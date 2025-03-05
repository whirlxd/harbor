
class UniquenessIndexToHashOnHeartbeats < ActiveRecord::Migration[8.0]
  def change
    attributes = [
      :user_id,
      :branch,
      :category,
      :dependencies,
      :editor,
      :entity,
      :language,
      :machine,
      :operating_system,
      :project,
      :type,
      :user_agent,
      :line_additions,
      :line_deletions,
      :lineno,
      :lines,
      :cursorpos,
      :project_root_count,
      :time,
      :is_write
    ]

    add_column :heartbeats, :fields_hash, :text

    Heartbeat.find_each do |heartbeat|
      heartbeat.send(:set_fields_hash!)
      heartbeat.save!
    end

    # error if any two heartbeats have the same fields_hash
    duplicates = false
    Heartbeat.group(:fields_hash).having("count(*) > 1").count.each do |fields_hash, count|
      puts "Duplicate fields_hash: #{fields_hash} (count: #{count})"
      duplicates = true
    end

    raise "Duplicate in fields_hash" if duplicates

    change_column_null :heartbeats, :fields_hash, false
    add_index :heartbeats, :fields_hash, unique: true

    # clean up the index from ./20250303180842_create_heartbeats.rb
    remove_index :heartbeats,
                 attributes,
                 unique: true
  end
end
