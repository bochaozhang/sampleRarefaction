def calculateRarefaction():
    header, matrix = readTSV('parameters.tsv')
    richness = float(matrix[0][0])
    T = float(matrix[0][1])
    Q1 = float(matrix[0][2])
    Q2 = float(matrix[0][3])
    output_file = open('addtionalSamples.tsv','w')
    output_file.write('coverage\tsamples needed\n')
	
    coverages = [x * 0.01 for x in range(5,96)]
    for coverage in coverages:
        G = calculateSampleNeeded(richness,T,Q1,Q2,coverage)
        output_file.write(str(coverage) + '\t' + str(G))
        output_file.write('\n') 
            
    output_file.close()


def calculateSampleNeeded( richness,T,Q1,Q2,g ):
    import math
    # Calculate Q0_chao2 (number of clones not detected)
    if Q2 > 0:
	chao2 = ( (T - 1) / T ) * ( Q1**2 / (2*Q2) )
    else:
	chao2 = ( (T - 1) / T) * ( (Q1 * (Q1 - 1)) / (2 * (Q2 + 1)) )
	
    # Calculate individual G needed to reach coverage g    
    S_obs = richness
    S_est = S_obs + chao2
    if S_obs / S_est >= g:
    	t_g = 0
    else:
    	t_g = math.log(1 - T/(T-1) * 2*Q2/Q1**2 * (g*S_est - S_obs)) / math.log(1 - 2*Q2/( (T-1)*Q1 + 2*Q2 ));

    return int(math.ceil(t_g))
    

def readTSV( input_file ):
    import csv
    
    with open(input_file,'rb') as tsvin:
        tsvin = csv.reader(tsvin, delimiter='\t')
        array = []
        for row in tsvin:
            array.append(filter(None, row))
    header = array[0]
    matrix = array[1:]

    return header, matrix

if __name__ == '__main__':
    calculateRarefaction()
