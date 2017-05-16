Calculate additional samples needed using sample based rarefaction
=============

Bochao Zhang

This script will read data from immuneDB and calculate the number of addtional sample needed to reach certain proportion of coverage.

## Usage

```
-d name of database
-s name of subject
-f field of the columns used to separate data
-t size threshold, lower bound clone size, see below
```
For example

```
bash sampleRarefaction.sh -d lp11 -s D207 -f tissue -t 20
```
will calculate the number of additional sample needed to reach 0.5:0.01:0.95 coverage for each tissue in subject D207 from database lp11, using only clones that have at least 20 instances in at least one tissue

** Note: you will need permission to access databases, replace your username and pwd in security.cnf. **

## Methods
### Instance
We considered clone size to be the sum of the number of uniquely mutated sequences and all the different instances of the same unique sequence that are found in separate sequencing libraries. We refer to this hybrid clone size measure as “unique sequence instances”.

### Lower bound clone size
Our assumption is clones with larger size are easier to sample. So number of additional sample is calculated based on lower bound clone size. This lower bound clone size is defined as at least *X* instances in at least compartment. And they are generally referred to as C*X* clones, where *X* denotes the lower bound clone size.

### Calculation
[Models and estimators linking individual-based and sample-based rarefaction, extrapolation and comparison of assemblages](https://academic.oup.com/jpe/article/5/1/3/1296712/Models-and-estimators-linking-individual-based-and)

## Output files
The code will output one tsv file for each compartment with feature with prefix:
[subject]-[compartment]-[C*X*]-
in which *X* denotes the lower bound clone size:

**addtionalSamples.tsv**: contains the number of additional samples needed to achieve 0.5 to 0.95 coverage, with step of 0.01. Numbers are rounded to the nearest integar towards positive infinity.