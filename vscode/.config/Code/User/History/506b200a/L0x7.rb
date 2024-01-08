module Types
  class Types::Tables::AccessControl::CommunityPropertyUsersTableType < Types::BaseObject
    connection_type_class(Types::BaseConnectionObject)

    field :full_user_name,   String, null: true
    field :property_id,      ID,     null: false
    field :property_name,    String, null: false
    field :property_user_id, ID,     null: false
  end
end
