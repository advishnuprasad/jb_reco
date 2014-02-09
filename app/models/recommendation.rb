# An example how to implement a movie recommendation engine using the neography gem
# It's based on Marko Rodriguez article http://markorodriguez.com/2011/09/22/a-graph-based-movie-recommender-engine/
# but here we use Cypher instead of Gremlin
#
# To run the example you have to install neo4j and the neography gem
# You can download the data files from http://www.grouplens.org/node/73

require 'neography'

neo = Neography::Rest.new("http://localhost:7474")

neo.execute_script("g.clear();")

neo.set_node_auto_index_status(true)
neo.create_node_auto_index
neo.add_node_auto_index_property('type')
neo.add_node_auto_index_property('movieId')
neo.add_node_auto_index_property('usereId')
neo.add_node_auto_index_property('title')

movieNodes = {}
generaNodes = {}

$stdout << "\nReading Movies\n"
File.open('movies.dat','r:iso-8859-1').readlines.map do |l|
  (id, title, genera) = l.strip.split('::')
  movieNodes[id.to_i] = m = Neography::Node.create(type: 'Movie', title: title, movieId: id.to_i )
  genera.split('|').each do |g|
    generaNodes[g] = Neography::Node.create(type: 'Genera', genera: g) unless generaNodes.key?(g)
    m.outgoing(:hasGenera) << generaNodes[g]
  end
  $stdout << "."
end

occupations = ['other', 'academic/educator', 'artist',
  'clerical/admin', 'college/grad student', 'customer service',
  'doctor/health care', 'executive/managerial', 'farmer',
  'homemaker', 'K-12 student', 'lawyer', 'programmer',
  'retired', 'sales/marketing', 'scientist', 'self-employed',
  'technician/engineer', 'tradesman/craftsman', 'unemployed', 'writer']

occupationNodes = occupations.map{ |o| Neography::Node.create(type: 'Occupation', occupation: o)}

$stdout << "\nReading Users \n"
userNodes = {}
File.readlines('users.dat').map do |l|
  (id, gender, age, occupation, zipcode) = l.strip.split('::')
  userNodes[id.to_i] = u = Neography::Node.create(type: 'User', userId: id.to_i, gender: gender, age: age.to_i, zipcode: zipcode)
  u.outgoing(:hasOccupation) << occupationNodes[occupation.to_i]
  $stdout << '.'
end

batch = []
$stdout << "\nReading Ratings\n"
File.readlines('ratings.dat').map do |l|
  (userId, movieId, stars, timestamp) = l.strip.split('::')
  batch << [:create_relationship, :rated, userNodes[userId.to_i], movieNodes[movieId.to_i], {stars: stars.to_i}]
  #Neography::Relationship.create( :rated, userNodes[userId.to_i], movieNodes[movieId.to_i], {stars: stars.to_i})
  $stdout << '.'
end

$stdout << "\nInserting #{batch.length} ratings\n"

# Break in small batches through the REST API
batch.each_slice(1000) do |slice|
  neo.batch *slice
  $stdout << '.'
end

$stdout << "\nCompleted\n"

#Queries

#The distribution of the occupations among the user population
puts neo.execute_query("start n=node:node_auto_index(type='User') match (n)-[:hasOccupation]->(o) return o.occupation, count(*) order by count(*) desc")

#Average age of the users
puts neo.execute_query("start n=node:node_auto_index(type='User') return avg(n.age)")

### Basic Collaborative Filtering
# Fetch Toy Story from the index
m=Neography::Node.load(neo.get_node_index(:node_auto_index, :title, 'Toy Story (1995)').first['self'])
puts m


#Which users gave Toy Story more than 3 stars?
puts m.incoming(:rated).filter("position.length() == 1 && position.lastRelationship().getProperty('stars')>3;").to_a

#Which users gave Toy Story more than 3 stars and what other movies did they give more than 3 stars to?
puts neo.execute_query("start n=node(#{m.neo_id}) match (n)<-[r1:rated]-(x)-[r2:rated]->(y) where (r1.stars>3 and r2.stars>3) return y.title limit 5")

#Which movies are most highly co-rated with Toy Story?
puts neo.execute_query("start n=node(#{m.neo_id}) match (n)<-[r1:rated]-(x)-[r2:rated]->(y) where (r1.stars>3 and r2.stars>3) return y.title,count(*) order by count(*) desc limit 5")

#Mixing in Content-Based Recommendation
#Which movies are most highly co-rated with Toy Story that share a genera with Toy Story?
puts neo.execute_query("start n=node(#{m.neo_id}) match (y)-[:hasGenera]->(g)<-[:hasGenera]-(n)<-[r1:rated]-(x)-[r2:rated]->(y) where (r1.stars>3 and r2.stars>3) return y.title,count(*) order by count(*) desc limit 5")