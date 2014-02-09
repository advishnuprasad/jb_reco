def create_graph
  create_node_properties
  create_nodes
  # create_nodes_index
  # create_relationship_properties
  # create_relationships
  # create_relationships_index
end

def create_node_properties
  @node_properties = ["type", "member_id", "name"]
  generate_node_properties(@node_properties)
end

def generate_node_properties(args)
  File.open("nodes.csv", "w") do |file|
    file.puts args.join("\t")
  end
end

def create_nodes
  MemberPlan.first(1000).collect {|mp| [mp.id, mp.first_name]}
  @nodes =  {"jbMember" => { "start" => 1, "end"   => 1000, "props" => user_values } }
  @nodes.each{ |node| generate_nodes(node[0], node[1])}
end

def generate_nodes(type, hash)
  puts "Generating #{(1 + hash["end"] - hash["start"])} #{type} nodes..."
  nodes = File.open("nodes.csv", "a")

  (1 + hash["end"] - hash["start"]).times do |t|
      properties = [type] + hash["props"][t]
      nodes.puts properties.join("\t")
  end
  nodes.close
end