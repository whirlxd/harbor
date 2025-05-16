module HasTableSync
  extend ActiveSupport::Concern

  included do
    validates :airtable_fields, presence: true
    validates :airtable_id, presence: true, uniqueness: true
  end

  class_methods do
    def has_table_sync(pat:, base:, table:)
      @table_sync_pat = pat
      @table_sync_base = base
      @table_sync_table = table

      @table = Norairrecord.table(pat, base, table)

      def pull_all_from_airtable!
        records = @table.all

        records.each do |record|
          find_or_initialize_by(airtable_id: record.id).update(airtable_fields: record.fields)
        end
      end
    end
  end
end
