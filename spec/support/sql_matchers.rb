# Helpers for asserting on a relation's SQL without executing it.
#
# Identifier quoting is adapter-specific — SQLite emits "scenes"."id" while
# nulldb emits 'scenes'.'id' — so a raw to_sql assertion passes on one adapter
# and fails on the other. Strip the quotes and assert on the shape instead.
module SqlMatchers
  # "SELECT \"scenes\".* FROM \"scenes\" WHERE \"scenes\".\"resolved_at\" IS NULL"
  #   => "SELECT scenes.* FROM scenes WHERE scenes.resolved_at IS NULL"
  def unquoted_sql(relation)
    sql = relation.respond_to?(:to_sql) ? relation.to_sql : relation.to_s
    sql.gsub(/["'`]/, "")
  end
end

RSpec.configure do |config|
  config.include SqlMatchers
end
