class GenerateGraph
  def self.create_graph
    create_node_and_relationships
    # create_node_properties
    # create_nodes
    create_nodes_index
    # create_rel_properties
    # create_relationships
    create_relationships_index
  end

  def self.create_node_properties
    @node_properties = ["type", "member_id", "name"]
    generate_node_properties(@node_properties)
  end

  def self.generate_node_properties(args)
    File.open("nodes.csv", "w") do |file|
      file.puts args.join("\t")
    end
  end

  def self.create_node_and_relationships1
    count = 1

    File.open("nodes.csv", "w") do |file|
      file.puts(["type", "entity_id"].join("\t"))
    end

    File.open("rels.csv", "w") do |file|
      header = ["start", "end", "type"]
      file.puts header.join("\t")
    end

    mps = MemberPlan.first(1000)
    nodes = File.open("nodes.csv", "a")
    rels = File.open("rels.csv", "a")

    mps.each_with_index do |mp, index|

      if mp.rentals.present?
        nodes.puts("jbMember\t#{mp.id}")
        i = count
        count += 1
      end

      mp.rentals.each_with_index do |r, r_index|
        nodes.puts("jbTitle\t#{r.legacy_title_id}")
        count += 1
        rels.puts("#{i}\t#{i+r_index+1}\tread")
      end
    end
  end

  def self.create_node_and_relationships
    count = 1

    File.open("nodes.csv", "w") do |file|
      file.puts(["entity_id", "t_name:string:name", "type"].join("\t"))
    end

    File.open("rels.csv", "w") do |file|
      header = ["t_name:string:name", "t_name:string:name", "type"]
      file.puts header.join("\t")
    end

    # categories = Category.all
    p "Creating Category nodes"
    nodes = File.open("nodes.csv", "a")
    rels = File.open("rels.csv", "a")
    Category.all.find_each do |c|
      nodes.puts("#{c.id.to_i}\tc#{c.id.to_i}\tjbCategory")
    end
    p "Creating Title nodes"
    # titles = Title.all
    Title.all.find_each do |title|
      if title.category.present?
        nodes.puts("#{title.id.to_i}\tt#{title.id.to_i}\tjbTitle")
        rels.puts("t#{title.id.to_i}\tc#{title.category.id.to_i}\thasCategory")
      end
    end

    p "Creating MemberPlan nodes"
    MemberPlan.all.find_each do |mp|
      nodes.puts("#{mp.id}\tm#{mp.id}\tjbMember") if mp.returns.present?
      mp.rentals.each do |r|
        rels.puts("m#{mp.id}\tt#{r.legacy_title_id.to_i}\tread")
      end
    end
    nodes.close
    rels.close
  end

  def self.create_nodes_index
    puts "Generating Node Index..."
    nodes = File.open("nodes.csv", "r")
    nodes_index = File.open("nodes_index.csv","w")
    counter = 0

    while (line = nodes.gets)
      nodes_index.puts "#{counter}\t#{line}"
      counter += 1
    end

    nodes.close
    nodes_index.close
  end

  def self.create_relationships_index
    puts "Generating Relationship Index..."
    rels = File.open("rels.csv", "r")
    rels_index = File.open("rels_index.csv","w")
    counter = -1

    while (line = rels.gets)
      size ||= line.split("\t").size
      rels_index.puts "#{counter}\t#{line.split("\t")[3..size].join("\t")}"
      counter += 1
    end

    rels.close
    rels_index.close
  end

  def self.load_graph
    puts "Running the following:"
    command ="java -server -d64 -Xmx4G -jar /home/vishnu/zazen/neo4j_memp/batch-import/target/batch-import-jar-with-dependencies.jar /var/lib/neo4j/data/graph.db nodes.csv rels.csv node_index vertices fulltext nodes_index.csv rel_index edges exact rels_index.csv"
    puts command
    exec command
  end


  def self.create_nodes
    # user_values = MemberPlan.first(1000).collect{|mp| [mp.id, mp.first_name]}
    user_values = Return.includes(:member_plan).limit(1000).collect {|r| [r.member_plan_id, r.legacy_title_id]}
    @nodes =  {"jbMember" => { "start" => 1, "end"   => 1000, "props" => user_values } }
    @nodes.each{ |node| generate_nodes(node[0], node[1])}
  end

  def self.generate_nodes(type, hash)
    puts "Generating #{(1 + hash["end"] - hash["start"])} #{type} nodes..."
    nodes = File.open("nodes.csv", "a")

    (1 + hash["end"] - hash["start"]).times do |t|
        properties = [type] + hash["props"][t][0]
        nodes.puts properties.join("\t")
    end
    nodes.close
  end

  def create_rel_properties
    File.open("rels.csv", "w") do |file|
      header = ["start", "end", "type"]
      file.puts header.join("\t")
    end
  end

  def self.create_relationships

    rels = {"user_to_company"  => { "from"  => @nodes["user"],
                                    "to"     => @nodes["company"],
                                    "number" => 21000,
                                    "type"   => "belongs_to",
                                    "connection" => :sequential }
            }

    # Write relationships to file
    rels.each{ |rel| generate_rels(rel[1])}
  end
end