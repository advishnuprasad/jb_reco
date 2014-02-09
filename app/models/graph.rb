class Graph
  def initialize
    @neo = Neography::Rest.new
  end

  def neo
    @neo
  end

  def create_member_plan(id, name)
    existing_node = Neography::Node.find("member_id", "id:#{id}")
    return existing_node if existing_node
    node = Neography::Node.create("id" => id, "name" => name)
    node.add_to_index("member_id", "id", id)
    @neo.add_label(node, "Member")
    node
  end

  def create_title(id, title)
    existing_node = Neography::Node.find("title_id", "title_id:#{id}")
    return existing_node if existing_node
    node = Neography::Node.create("title_id" => id, "title" => title)
    node.add_to_index("title_id", "title_id", id)
    @neo.add_label(node, "Title")
    node
  end

  def create_category(id, category)
    existing_node = Neography::Node.find("category_id", "category_id:#{id}")
    return existing_node if existing_node
    node = Neography::Node.create("category_id" => id, "category" => category)
    node.add_to_index("category_id", "category_id", id)
    @neo.add_label(node, "Category")
    node
  end

  def make_relationship
    mps = MemberPlan.first(1000)
    mps.each do |mp|
      m = create_member_plan(mp.id, mp.first_name)
      mp.returns.each do |r|
        t = create_title(r.title.id, r.title.title)
        mt = neo.create_relationship("read", m, t)
        ct = create_category(r.title.category.try(:id).to_i, r.title.category.try(:name))
        tct = neo.create_relationship("hasCategory", t, ct)
      end
    end
    # m.rentals.each do |r|
    #   t = create_title(r.title.id, r.title.title)
    #   m = create_member_plan(r.member_plan.id, r.member_plan.first_name)
    #   r = neo.create_relationship("read", m, t)
    # end
    # titles = Title.where(:id => 180100)
    # titles.each do |title|
    #   t = create_title(title.id, title.title)
    #   title.rentals.each do |r|
    #     m = create_member_plan(r.member_plan.id, r.member_plan.first_name)
    #     r = neo.create_relationship("read", m, t)
    #   end
    # end
    # titles = Title.last(100)
    # titles.each do |title|
    #   t = create_title(title.id, title.title)
    #   title.rentals.each do |r|
    #     m = create_member_plan(r.member_plan.id, r.member_plan.first_name)
    #     r = neo.create_relationship("read", m, t)
    #   end
    # end
  end


  def gremlin_reco_titles(node)
    neo.execute_script("g.V('name',node_id).out('read').out('hasCategory').dedup.in('hasCategory').in('read').except([g.V('name',node_id)]).groupCount().cap().orderMap(T.decr).outE.inV[0..20].title_id", {:node_id => node.name})
  end

  def recommeded_titles(node)
    neo.execute_query("MATCH (member:Member {id: #{node.id}})-[:read]->(title)<-[:read]-(other_members)-[:read]->(other_titles)
      RETURN other_titles.title_id, other_titles.title")["data"]
  end

  def those_who_read_this_title_also_read_this(title)
    neo.execute_query("MATCH (title:Title {title_id:#{title.title_id}})<-[:read]-(members)-[:read]->(related_titles) RETURN related_titles.title_id, related_titles.title")["data"]
  end

  def execute_query
    neo.execute_query("MATCH (m:User)-[:READ]->(new_titles)<-[:READ]-(m1:User {id: 1})
with  distinct m as o_m
MATCH (o_m)-[:READ]->(new_titles)
return distinct new_titles.category, count(new_titles.category), o_m.id  order by o_m.id
")
  end

  def get_all_path
    paths =  neo.get_paths(start_node,
                          destination_node,
                          {"type"=> "friends", "direction" => "in"},
                          depth=4,
                          algorithm="allSimplePaths")
  end
end


# "MATCH p=shortestPath((title:Title {title_id:240561})-[*]-(title:Title {title_id: 180100})) RETURN p"


# k = g.neo.execute_query("MATCH (member:Member {id: 6083})-[:read]->(title)<-[:read]-(other_members) RETURN other_members.id, other_members.name")["data"]

# k = g.neo.execute_query("MATCH p=shortestPath((title:Title {title_id:240561})-[*]-(title:Title {title_id: 180100})) RETURN p")["data"]

# # # MATCH (tom:Person {name:"Tom Hanks"})-[:ACTED_IN]->(m)<-[:ACTED_IN]-(coActors) RETURN coActors.name


# k = g.neo.execute_query("MATCH (member:Member {id: 39099})-[:read]->(title)<-[:read]-(other_members)-[:read]->(other_titles) RETURN other_titles.title_id, other_titles.title")["data"]


# CREATE (user1:JbMember {name: "Vishnu"})
# CREATE (user2:JbMember {name: "John"})
# CREATE (user3:JbMember {name: "Amit"})
# CREATE (user4:JbMember {name: "Hemanth"})
# CREATE (user5:JbMember {name: "Surabhi"})
# {title Inferno
# {category  Fiction
# {title The Lost Symbol
# {category  Fiction
# {title The Digital Fortress
# {category  Fiction
# {title Angels & Daemons
# {category  Fiction
# {title Davinci Code
# {category  Fiction
# {title Deception Point
# {category  Fiction