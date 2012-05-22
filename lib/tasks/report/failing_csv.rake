require 'csv'

namespace :report do
  desc "enrollments with a high number of failures"
  task :failing, [:fail_pct,:status] => :environment do |t,args|
    threshold_pct = args[:fail_pct].to_f / 100.0
    statuses = args[:status] ? [args[:status]] : Enrollment::VALID_STATUSES

    STATUS_LEGEND = {
      Notification::NEW       => '.',
      Notification::DELIVERED => '*',
      Notification::TEMP_FAIL => 'x',
      Notification::PERM_FAIL => 'X',
      Notification::CANCELLED => '-',
    }

#    puts 'Legend:'
#    puts '  ACTIVE  current enrollment status'
#    puts '  [...]   list of notifications w/ status, one char per notification'
#    puts '  |       30-day boundary, notifications to right within last 30 days'
#    puts '  (#)     # of failures in a row w/o a successful delivery since'
#    puts
#    puts 'Notification Statuses:'
#    puts Notification::VALID_STATUSES.map {|s| "  #{STATUS_LEGEND[s]}  #{s}" }
#    puts

    columns = [ 'First name', 'Last name','Phone number','Phone number length', 'language','id','External user id', 
	'status', 'Method', 'Message stream','old status','new status',
	'Older Notifications count','Older New count','Older Delivered count',
	'Older Notifications count','Older New count','Older Delivered count',
	'Newer Temp Fail count','Newer Perm Fail count','Newer Cancelled count',
	'Newer Temp Fail count','Newer Perm Fail count','Newer Cancelled count',
	'tail fails' ]
    puts CSV.generate_line([ *columns ])
    Enrollment.where(:status => statuses).each do |enrollment|
      notifications = enrollment.notifications
      total = notifications.where(:status => Notification::INACTIVE_STATUSES).count
      failed = notifications.where(:status => Notification::PERM_FAIL).count
      fail_pct = total > 0 ? failed / total.to_f : 0
      next unless fail_pct >= threshold_pct

      older = notifications.where('delivery_date < ?', 30.days.ago)
      newer = notifications.where('delivery_date > ?', 30.days.ago)
#      print '%5s' % enrollment.id
      first_name = enrollment.first_name
      last_name = enrollment.last_name
      phone_number = enrollment.phone_number
      phone_number_length = phone_number.length
      language = enrollment.language
      id = enrollment.id
#      print "#{enrollment.ext_user_id} #{enrollment.delivery_method} "
      extid = "#{enrollment.ext_user_id}"
      method =  "#{enrollment.delivery_method}"
      #print '%9s [ ' % enrollment.status
      stat =  enrollment.status
      stream = enrollment.message_stream.name
      #print older.map {|n| STATUS_LEGEND[n.status] }
      old = older.map {|n| STATUS_LEGEND[n.status] }
      #print ' | '
      #print newer.map {|n| STATUS_LEGEND[n.status] }
      new = newer.map {|n| STATUS_LEGEND[n.status] }
      #print ' ]'
      older_notifications_count = older.count
      older_new_count = older.where(:status => 'NEW').count
      older_delivered_count = older.where(:status => 'DELIVERED').count
      older_temp_fail_count = older.where(:status => 'TEMP_FAIL').count
      older_perm_fail_count = older.where(:status => 'PERM_FAIL').count
      older_cancelled_count = older.where(:status => 'CANCELLED').count
      newer_notifications_count = newer.count
      newer_new_count = newer.where(:status => 'NEW').count
      newer_delivered_count = newer.where(:status => 'DELIVERED').count
      newer_temp_fail_count = newer.where(:status => 'TEMP_FAIL').count
      newer_perm_fail_count = newer.where(:status => 'PERM_FAIL').count
      newer_cancelled_count = newer.where(:status => 'CANCELLED').count
      tail_fails = notifications.where(:status => Notification::INACTIVE_STATUSES).reverse \
        .take_while {|n| n.status == Notification::PERM_FAIL}
      #print " (#{tail_fails.length})"      
      tail = "#{tail_fails.length}"      
      puts CSV.generate_line([first_name,last_name,phone_number,phone_number_length,
	language,id,extid,method,stat,stream,old,new,
	older_notifications_count,older_new_count,older_delivered_count,
	older_temp_fail_count,older_perm_fail_count,older_cancelled_count,
	newer_notifications_count,newer_new_count,newer_delivered_count,
	newer_temp_fail_count,newer_perm_fail_count,newer_cancelled_count,
	tail])
    end
  end
end