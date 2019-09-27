namespace :brexit_checker do
  desc "Notify Email Alert API subscribers about a change"
  task :change_notification, [:change_note_id] => :environment do |_, args|
    id = args[:change_note_id]
    change_note = BrexitChecker::ChangeNote.find_by_id(id)
    raise "Change note not found" if change_note.nil?

    mail = BrexitCheckerMailer.change_notification(change_note)

    criteria_rules = change_note.criteria_rules || change_note.action.criteria

    GdsApi.email_alert_api.create_message(
      title: mail.subject,
      url: change_note.action.title_url,
      body: mail.body.raw_source,
      sender_message_id: change_note.id,
      criteria_rules: format_criteria_rules(criteria_rules),
    )

  rescue GdsApi::HTTPConflict
    raise "Notification already sent"
  end

  def format_criteria_rules(criteria)
    if criteria.is_a? String
      return {
        type: "tag",
        key: "brexit_checklist_criteria",
        value: criteria,
      }
    end

    if criteria.is_a? Hash
      return Hash[criteria.map { |k, v| [k, format_criteria_rules(v)] }]
    end

    if criteria.is_a? Array
      return criteria.map { |c| format_criteria_rules(c) }
    end

    raise "Unexpected criteria class #{criteria}"
  end
end
