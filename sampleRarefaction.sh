# Get parameters needed for calculation

# Get input arguments
while getopts ":d:s:f:t:" opt; do
  case $opt in
    d) db_name=$OPTARG;;
    s) subject=$OPTARG;;
    f) feature=$OPTARG;;     
    t) size_threshold=$OPTARG;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1;;
  esac
done
echo -e "database: $db_name\nsubject: $subject\nlower clone size bound: $size_threshold"

# Get all features
features=$(mysql --defaults-extra-file=security.cnf -h clash.biomed.drexel.edu --database=$db_name -N -B -e "select distinct $feature from samples left join subjects on samples.subject_id = subjects.id where subjects.identifier='$subject'")
unique_features=$(echo "${features[@]}" | tr '\n' ' ')
echo "$feature: $unique_features"

# Get qualified clones
qualified_clones=()
for feat in ${unique_features}; do
	# Get sample ids
	sample_id=$(mysql --defaults-extra-file=security.cnf -h clash.biomed.drexel.edu --database=$db_name -N -B -e "select samples.id from subjects right join samples on subjects.id = samples.subject_id where subjects.identifier='$subject' and samples.$feature='$feat'")	
	sample_id=$(echo "${sample_id[@]}" | tr '\n' ',')
	sample_id=${sample_id::-1}

	# Filter clones by size (instance)
	clones=$(mysql --defaults-extra-file=security.cnf -h clash.biomed.drexel.edu --database=$db_name -N -B -e "select clone_id,count(distinct seq_id) from sequences where sample_id in ($sample_id) and clone_id is not NULL and functional=1 group by clone_id;")	
	flag=0
	for clone in ${clones}; do
		if (($flag==0)); then
			qualified_clones+=($clone)
			flag=1
		else
			if (($clone<$size_threshold)); then
				unset qualified_clones[${#qualified_clones[@]}-1]
			fi
			flag=0
		fi
	done	
done
qualified_clones=($(echo "${qualified_clones[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
echo "${#qualified_clones[@]} clones with at least $size_threshold instance(s) in at least one $feature"	
qualified_clones=$(printf ",%s" "${qualified_clones[@]}")
qualified_clones=${qualified_clones:1}	

# Calculate for each feature
for feat in ${unique_features}; do
	# Get sample ids
	sample_id=$(mysql --defaults-extra-file=security.cnf -h clash.biomed.drexel.edu --database=$db_name -N -B -e "select samples.id from subjects right join samples on subjects.id = samples.subject_id where subjects.identifier='$subject' and samples.$feature='$feat'")	
	
	# Get number of samples
	T=$(echo "$sample_id" | wc -l)
	
	sample_id=$(echo "${sample_id[@]}" | tr '\n' ',')
	sample_id=${sample_id::-1}
	
	# Get number of samples in each clone
	echo "select count(distinct sample_id) from sequences where sample_id in ($sample_id) and functional=1 and clone_id in ($qualified_clones) group by clone_id" > temp.txt
	map=$(mysql --defaults-extra-file=security.cnf -h clash.biomed.drexel.edu --database=$db_name -N -B < temp.txt)
	map=($map)
	rm temp.txt

	# Get richness
	richness=${#map[@]}	
	
	# Get number of singletons and doubletones
	q1=0
	q2=0
	for n in ${map[@]}; do		
		if (($n==1)); then			
			((q1++))
		fi
		if (($n==2)); then
			((q2++))
		fi		
	done

	# Print out
	echo -e "richness\tT\tQ1\tQ2" > parameters.tsv
	echo -e "$richness\t$T\t$q1\t$q2" >> parameters.tsv

	# Run python calculation
	python sampleRarefaction.py

	# Rename output
	output_file="$subject-$feat-C$size_threshold.tsv"
	mv addtionalSamples.tsv $output_file
	rm parameters.tsv
done





