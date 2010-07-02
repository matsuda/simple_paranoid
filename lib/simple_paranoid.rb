# 
# http://github.com/mislav/is_paranoid
# からdestroy機能だけ取り出したもの
# 
require 'active_record'

module SimpleParanoid

  def self.included(base) # :nodoc:
    base.extend ClassMethods
  end

  module ClassMethods
    def simple_paranoid
      extend SimpleParanoid::SingletonMethods
      include SimpleParanoid::InstanceMethods

      class << self
        alias_method_chain :delete_all, :deleted
      end

      named_scope :not_null, :conditions => "#{table_name}.deleted_at IS NULL"
    end
  end

  module SingletonMethods
    def delete_all_with_deleted(conditions = nil)
      self.update_all ["deleted_at = ?", current_time], conditions

      # sql = "DELETE FROM #{quoted_table_name} "
      # add_conditions!(sql, conditions, scope(:find))
      # connection.delete(sql, "#{name} Delete all")
    end

    def delete_without_deleted(id)
      delete_all_without_deleted([ "#{connection.quote_column_name(primary_key)} IN (?)", id ])
    end

    def destroy_without_deleted(id)
      if id.is_a?(Array)
        id.map { |one_id| destroy_without_deleted(one_id) }
      else
        find(id).destroy_without_deleted
      end
    end

    protected
    def current_time
      default_timezone == :utc ? Time.now.utc : Time.now
    end
  end

  module InstanceMethods
    def destroy
      return false if callback(:before_destroy) == false
      result = destroy_without_callbacks
      callback(:after_destroy)
      result
    end

    protected
    def destroy_without_callbacks
      # self.deleted_at = Time.now.utc
      self.deleted_at = self.class.send(:current_time)
      update_without_callbacks
    end

  end
end

ActiveRecord::Base.send :include, SimpleParanoid
