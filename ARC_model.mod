### ======================== ARC Tornado AMPL Code =================================================
### This is the AMPL code for the Alternatives for Resilient Communities software tornado model
### The code links with Python API to generate parameters and scenarios and call AMPL
### The details of the model can be found in the related paper (Hughes et al.)
### Contact: william.hughest@nist.gov


### ========================
### ======================== Set up model ==========================================================
### ========================


# Define some parameters for set sizes

param n_neighborhoods; # number of neighborhoods
param n_DS; # number of building damage states
param n_archetypes; # number of building archetypes (including retrofits)
param n_injuries; # number of injury classes
param n_retrofits; # number of retrofits 

# ==================================
# ================================== Define sets =====================================================
# ==================================

set N := {1..n_neighborhoods}; # set of neighborhoods

set K := {1..n_DS}; # set of building damage states

set A := {1..n_archetypes}; # set of building archetypes

set M := {1.. n_injuries}; # set of injury states

set R := {1..n_retrofits}; # set of retrofit strategies

set Q within {A, R, R}; # set of permissible upgrade combinations (archetype, from, to)

# =================================
# ================================= Define parameters ===============================================
# =================================

# ===================== Economic

param f_pw; # present worth factor

param B; # budget

# ====================== Buildings 

param x_b_0 {N, A, R}; # initial number of buildings of archetypes a in neighborhood n

param x_b_fix {N,A,R}; # fixed building stock, if applicable

param p_DS {N, A, R, K}; # probability of damage state k given archetype a in neighborhood n

param p_DS_for_casualties {N, A, R, K}; # probability of damage state k given archetype a in neighborhood n, given sheltered (casualties set to 0)

param c_b_ret {A,R,R}; # cost of retrofitting building to archetype a

param c_b_rep {A,K}; # cost of repairing building type a in damage state k

param c_d {N, A, R}; # dislocation cost in neighborhood n and archetype a 

param f_footprint {A}; # factor for building footprint size increase

# ===================== Casualties

param p_i {K,M}; # injurity probability of level m given damage state k 

param H {N,A}; # number of residents in archetype a in neighborhood n 

param c_cas {M}; # cost of casualty level m

# ====================== Debris

param V_db {N, A, R}; # volume of building debris in neighborhood n of archetype a and retrofit r

param C_dr; # debris removal cost

# =================================
# ================================= Define variables =============================================
# =================================

# ================================= Decision variables

var change_matrix {N, Q} integer >=0; # numnber of buildings moving from r to r'

# ================================Definitional variables

var x_b {N, A, R} integer >=0; # number of buildings in each neighborhood

var c_casualty; # casualty costs

var c_bld_rep; # building repair costs

var c_debris_bld; # buidling debris cost

var c_ret; # retrofit costs

var c_dislocation; # dislocation costs
 
# =====================================
# ===================================== Objective function ====================================================
# =====================================

minimize c_expected : f_pw*(c_bld_rep+c_casualty+c_dislocation+c_debris_bld) + c_ret;

# =====================================
# ===================================== Constraints ============================================================
# =====================================

# ==================================== Model constraints

# ======= Budget constraint

s.t. budget_constraint: c_ret <=B;

# Note: additional constraints are implemented using Pyhton API

# ================================== Definitional variables

s.t. D_x_b {n in N, a in A, r in R}:
    x_b[n, a, r] = x_b_0[n, a, r] + 
    sum{r_prime in R:(a, r_prime, r) in Q} change_matrix[n, a, r_prime, r]
    - sum{r_prime in R:(a, r, r_prime) in Q} change_matrix[n, a, r, r_prime]; # define x_b

# Casualty costs

s.t. D1: c_casualty = sum{n in N, m in M, a in A, k in K, r in R} c_cas[m]*p_i[k,m]*p_DS_for_casualties[n,a,r,k]*H[n,a]*x_b[n,a,r]*f_footprint[a]; # Define casualty cost

# Building repair cost

s.t. D2: c_bld_rep = sum{n in N, a in A, k in K, r in R} x_b[n,a,r]*c_b_rep[a,k]*p_DS[n,a,r,k]*f_footprint[a]; 
# Define building repair cost

# Debris removal cost for buildings

s.t. D3: c_debris_bld = sum{n in N, a in A, r in R} x_b[n,a,r]*V_db[n,a,r]*C_dr*f_footprint[a]; # Define debris removal cost

# Retrofit costs for buildings

s.t. D4: c_ret = sum{n in N, a in A, r in R, r_prime in R:(a,r,r_prime) in Q} change_matrix[n,a,r,r_prime]*c_b_ret[a,r,r_prime]; # Define retrofit cost

# Dislocation costs

s.t. D5: c_dislocation = sum{n in N, a in A,r in R} x_b[n,a,r]*c_d[n,a,r]*f_footprint[a]; # Define dislocation cost

