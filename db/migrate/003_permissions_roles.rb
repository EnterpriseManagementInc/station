class PermissionsRoles < ActiveRecord::Migration
  def self.up
    create_table :permissions do |t|
      t.string :action
      t.string :objective
    end

    create_table :permissions_roles, :id => false do |t|
      t.integer :permission_id
      t.integer :role_id
    end

    remove_column :roles, :create_entries
    remove_column :roles, :read_entries
    remove_column :roles, :update_entries
    remove_column :roles, :delete_entries
    remove_column :roles, :create_performances
    remove_column :roles, :read_performances
    remove_column :roles, :update_performances
    remove_column :roles, :delete_performances
    add_column :roles, :stage_type, :string

    rename_column :performances, :container_id, :stage_id
    rename_column :performances, :container_type, :stage_type
  end

  def self.down
    drop_table :permissions
    drop_table :permissions_roles

    add_column :roles, :create_entries, :boolean
    add_column :roles, :read_entries, :boolean
    add_column :roles, :update_entries, :boolean
    add_column :roles, :delete_entries, :boolean
    add_column :roles, :create_performances, :boolean
    add_column :roles, :read_performances, :boolean
    add_column :roles, :update_performances, :boolean
    add_column :roles, :delete_performances, :boolean
    remove_column :roles, :stage_type

    rename_column :performances, :stage_id,   :container_id
    rename_column :performances, :stage_type, :container_type
  end
end
