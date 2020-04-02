data{
  int<lower=0> N;
  int<lower=0> day0;
  int<lower=0> pop;
  vector[N] day;
  vector[N] deaths;
  vector[N] casos_obs;  
}

parameters {
  real<lower = 0, upper = 1> letalidade;  
  real<lower = 0, upper = 1000> casos_0; 
  vector<lower = 0, upper = .5>[N] r0;
  real<lower = 0> sigma_delta_r0;  
  real<lower = 0> sigma_obs;
}

transformed parameters {
  vector[N] casos;
  vector[N] contagios;

  contagios[1] = casos_0 * r0[1];
  casos[1]     = casos_0 + contagios[1];
  
  for (i in 2:N) {
    
    real contagiadores = 0;
    for (j in max(1, i - 27):(i-1)) {
      contagiadores = contagiadores + contagios[j];
    }
    
    // print("i: ", i);
    // print("r0: ", r0[i]);
    // print("contagios: ", contagios[i-1]);
    // print("contagiadores: ", contagiadores);
    
    contagios[i] = fmax(0, (1 - casos[i-1] / pop)) * contagiadores * r0[i];
    casos[i] = casos[i-1] + contagios[i];
  }
}

model {
  // prior
  letalidade ~ normal(0.01, 0.01);
  sigma_delta_r0 ~ normal(0, .001);
  sigma_obs ~ normal(0, .25);
  
  // first iteration
  r0[1] ~ normal(.03, .02);
  for (i in 2:N)
    r0[i] ~ normal(r0[i-1], sigma_delta_r0);

  // only people catching coronavirus 20 days ago can die
  for (i in 1:N) {
    
    // normal approximation to binomial
    if (i > 7) {
      
      real em_risco = 0;
      for (j in max(1, i - 24):(i-6)) {
        em_risco = em_risco + contagios[j];
      }
      
      deaths[i] ~ normal(letalidade * em_risco, sqrt(letalidade * em_risco)); 
    }

    // observation error grows with the number of existing cases
    casos_obs[i] ~ normal(casos[i], casos[i] * sigma_obs); 
  }
}
