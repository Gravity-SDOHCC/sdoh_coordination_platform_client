module ApplicationHelper
  include SessionsHelper
  include TasksHelper

  def organizations
    Rails.cache.fetch(organizations_key, expires_in: 1.day) do
      response = get_cp_client.search(FHIR::Organization, search: {  parameters: { type: 'cbo', _sort: "-_lastUpdated" }}).resource

      if response.is_a?(FHIR::Bundle)
        entries = response.entry.map(&:resource)
        entries.map { |entry| Organization.new(entry) }
      end
    end
  end

  def bootstrap_class_for(flash_type)
    case flash_type.to_sym
    when :success
      "success"
    when :error
      "danger"
    when :alert
      "warning"
    when :notice
      "info"
    else
      flash_type.to_s
    end
  end

  def colorize_json(json)
    output = ""
    tokens = {
      '{' => 'color: #ffc35f;',
      '}' => 'color: #ffc35f;',
      '[' => 'color: #ffc35f;',
      ']' => 'color: #ffc35f;',
      ',' => 'color: #ffc35f;',
      ':' => 'color: #0069ff;',
      'true' => 'color: green;',
      'false' => 'color: red;',
      'null' => 'color: #baa2cd;'
    }

    json.scan(/(".*?"|{|}|[|]|,|:|true|false|null|-?\d+(\.\d+)?([eE][+-]?\d+)?|\s+)/) do |token|
      color = tokens[token.first] || ('color: #3ea4dc;' if token.first.start_with?('"')) || nil
      if color
        output += "<span style='#{color}'>#{ERB::Util.html_escape(token.first)}</span>"
      else
        output += ERB::Util.html_escape(token.first)
      end
    end

    output.html_safe
  end
end
