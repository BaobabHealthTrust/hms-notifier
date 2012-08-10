require 'csv'

namespace :enrollments do
  desc "Load enrollments from hotline csv export"  
  task :load_csv => :environment do
    CSV.open("/vagrant/csv/individual_current_enrollments.csv", 'r') do |row|
      next unless row[2] # skipping date range header
#      print "First_name: #{row[0]}, Last_name: #{row[1]}, National_id: #{row[2]}, IVR_id: #{row[3]}," +
#        "Tips: #{row[4]}, Phone_type: #{row[5]}, Phone_number: #{row[6]}, Language: #{row[7]}, " + 
#        "Message_Type: #{row[8]}, Content: #{row[9]},Relevant_Date: #{row[10]}\n"
      first_name = row[0]
      last_name = row[1]
      national_id = row[2]
      ivr_id = row[3]
      tips = row[4]
      phone_type = row[5]
      phone = row[6]
      language = row[7]
      message_type = row[8]
      stream_name = row[9]
      relevant_date = row[10]
      phone = phone.to_s.gsub(/\s+/, '').sub(/^0/, '265')
      ext_user_id = "#{ivr_id}/#{national_id}"
      person_log_summary = "#{first_name} #{last_name} #{phone} #{ext_user_id}"

#      puts "#{person_log_summary}"
#      puts "     #{encounters.size} total, last #{encounters.last.date_created}  #{encounters.last.encounter_id}: #{encounter_data.inspect}"

      enrollment_ids_to_cancel = Enrollment.active.map(&:id)

      content_type_to_stream = {
        "Child" => "child",
        "Pregnancy" => "pregnancy"
      }

      lang_to_lang = {
        "Chichewa" => "Chichewa",
        "Chiyao" => "Chiyao"
      } 
      message_type_to_delivery = {
        "Send sms" => "SMS",
        "Voice" => "IVR"
      }

      next unless tips == "Yes"
      next if !phone.present? || phone == '--'

      #all further 'next' skips are unexpected and should be logged as warnings
      #the intent is to catch holes in mnch-hotline's minimal enrollment validation logic. 
      skip_text = "Enrollment skipped for #{person_log_summary}"


      if !phone.present? || phone == "--"
        puts "Unsupported phone number \"#{phone}\". #{skip_text}"
        next
      end

      unless (stream_name == "Pregnancy" || stream_name == "Child")
        puts "Unsupported message type \"#{stream_name}\". #{skip_text}"
        next
      end

      unless relevant_date =~ /\d{4}-\d{2}-\d{2}/
        puts "Unsupported date format \"#{relevant_date}\". #{skip_text}"
        next
      end

      stream = MessageStream.find_by_name(stream_name.downcase) 
      raise "stream not found for name #{stream_name}" if stream.nil?
      if stream_name=="Child"
        stream_start = relevant_date
      elsif stream_name=="Pregnancy"
#        pg_status_encounter = Encounter.pg_status.where(:patient_id=>patient_id).order("date_created DESC").first 
#        if pg_status_encounter.nil?
#          puts "#{skip_text} Pregnancy enrollment without pregancy status encounter"
#          next
#        end
        # curiously, EDD is stored as value_text, and has two possible names
        due_date_text = relevant_date
        if due_date_text.nil? || due_date_text == '--'
          puts "#{skip_text} Pregnancy enrollment with pregnancy status encounter but without EDD "
#         " #{pg_status_encounter.encounter_id}, #{pg_status_encounter.obs_hash.inspect}"
          next
        end
        stream_start = Date.parse(due_date_text) - 40.weeks
      end

      #community phones disallowed from voice delivery
      if phone_type == "Community phone" && message_type == "Voice" 
        puts "Voice enrollment for community phone. #{skip_text}"
        next
      end

      raise "Unknown language #{language}" unless language = lang_to_lang[language]
      raise "Unknown delivery type #{message_type}" unless delivery_method = message_type_to_delivery[message_type]



      if enrollment = Enrollment.active.where(:ext_user_id=>ext_user_id,:message_stream_id=>stream.id).first
        enrollment_ids_to_cancel.delete(enrollment.id)
      else
        enrollment = Enrollment.new
      end

      enrollment.attributes = {
        :first_name => first_name,
        :last_name => last_name,
        :phone_number => phone,
        :message_stream_id => stream.id,
        :language => language,
        :delivery_method => delivery_method,
        :stream_start => stream_start,

        :ext_user_id => ext_user_id,
        :status => "ACTIVE"
      }
      #puts enrollment.inspect
      enrollment.save!  if ENV['HMS_SAVE_ENROLLMENTS']

    end

    if ENV['HMS_SAVE_ENROLLMENTS']
      Enrollment.find(enrollment_ids_to_cancel).each do |e|
        e.update_attributes(:status => Enrollment::CANCELLED)
      end
    end
  end
end
