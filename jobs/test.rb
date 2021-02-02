tablename = 'stop5_3data1'
n = {'stop5_3data1' => 9, 'stop5_2data1' => 8}[tablename]

sql = <<-SQL
SELECT *
FROM 'C:/c/5.1/PTadv/Hasselt-Genk/orgin/Variant52/#{tablename}.db'
SQL


data_new = OtQuery.execute_to_a(sql)
data_old = OtQuery.execute_to_a(sql.gsub(/orgin/, 'orgout'))

hsh_new = data_new.inject({}) { |hsh, v| hsh[v[0..n]] = v[n+1..-1]; hsh }
hsh_old = data_old.inject({}) { |hsh, v| hsh[v[0..n]] = v[n+1..-1]; hsh }
p [hsh_new, hsh_old].map {|e| e.size}
p [hsh_new, hsh_old].map {|e| e.keys.uniq.size}

p (hsh_new.keys - hsh_old.keys).size
p (hsh_old.keys - hsh_new.keys).size


p "Entries that are in orgin but not in orgout"
(hsh_new.keys - hsh_old.keys).each { |key| p [key, hsh_new[key]] if hsh_new[key].sum > 0 }
p "Entries that are in orgin but not in orgout"
(hsh_old.keys - hsh_new.keys).each { |key| p [key, hsh_old[key]] if hsh_old[key].sum > 0 }
