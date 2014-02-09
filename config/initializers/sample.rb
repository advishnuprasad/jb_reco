require 'rubygems'
require 'neography'

@neo = Neography::Rest.new

def create_person(name)
  @neo.create_node("name" => name)
end

def make_mutual_friends(node1, node2)
  @neo.create_relationship("friends", node1, node2)
  @neo.create_relationship("friends", node2, node1)
end

def suggestions_for(node)
  node_id = node["self"].split('/').last.to_i
  @neo.execute_script("g.v(node_id).in('friends').in('friends').dedup.filter{it != g.v(node_id)}.name", {:node_id => node_id})
  # @neo.execute_script("g.v(node_id).
  #                        in('friends').
  #                        dedup.
  #                        filter{it != g.v(node_id)}.
  #                        name", {:node_id => node_id})
end

# def suggestions_for(node)
#   @neo.traverse(node,"nodes", {"order" => "breadth first",
#                                           "uniqueness" => "node global",
#                                           "relationships" => {"type"=> "friends", "direction" => "in"},
#                                           "return filter" => {
#                                             "language" => "javascript",
#                                             "body" => "position.length() == 2;"},
#                                           "depth" => 2})
# end

johnathan = create_person('Johnathan')
mark      = create_person('Mark')
phill     = create_person('Phill')
mary      = create_person('Mary')
luke      = create_person('Luke')

make_mutual_friends(johnathan, mark)
make_mutual_friends(mark, mary)
make_mutual_friends(mark, phill)
make_mutual_friends(phill, mary)
make_mutual_friends(phill, luke)

puts "Johnathan should become friends with #{suggestions_for(johnathan).join(', ')}"

# RESULT
# Johnathan should become friends with Mary, Phill