## Dependencies ##
require(R2WinBUGS)
library(data.table)
library(here)

BD <-  "path-to-winbugs-on-your-machine"

#Load point-level (primary) data, neighborhood information, and grid (secondary) data
### See GitHub README for file descripions ###

block <- fread('Data/GridCovariates_CoS.csv')
coarse.block <- fread('Data/eBird_grid.csv')
grid1 <- fread('Data/BBA_cleaned.csv')
load('Data/high.Rdata')
load('Data/low.Rdata')
load('Data/grid1.wbnb.Rdata')

### ### ### ### ### ### ### ### ### ### ### ###

# MCMC Settings
ni = 50000
nb = 10000
nt = 50
nc = 3

### ### ### ### ### ### ### ### ### ### ### ###

# Prepare data, set initial values, and indicate which values to be returned from BUGS #


#Bundle data
#Values needed:
# Y = A vector with length equal to number of sampling locations (nsite) containing information about counts of detections of focal species. Range of Integer value = (0, number of visits)
# E = A vector with length equal to the number of grid cells (ncell) containing summarized effort for secondary data source
# W = A vector with length equal to the number of grid cells (ncell) containing summarized effort for secondary data source for grid with coarser resolution than primary data
# num = A vector of length ncell (number of grid cells) giving the number of neighbors for each cell
# adj = A vector listing the ID numbers of the adjacent cells for each cell.
# weights = A vector of length `adj` giving unnormalized wights associated with each pair of cells. 
# ncell = An integer value for the number of grid cells for the primary data source (finest resolution)
# cell = A vector listing the ID numbers of the point-level sampling locations within a particular cell. 
# nsite = An integer value for the number of point-level sampling locations.
# forest = A vector of length ncell. This can be any covariate(s) of interest, we used average forest cover in a grid cell.
# ncell_eb = An integer value for the number of grid cells for the secondary data source (coarser resolution than primaryd data source)
# low = A vector of length ncell. This tells BUGS how many finer cells (ncell) are contained within a coarser cell (ncell_eb)
# high = A vector of length ncell. This tells BUGS how many finer cells (ncell) are contained within a coarser cell (ncell_eb)

  car.data <- list(Y = grid1$total.dets,
                    E = coarse.block$total.eHours,
                    W = coarse.block$total.eCount,
                    num = grid1.wbnb$num, 
                    adj = grid1.wbnb$adj,
                    weights = grid1.wbnb$weights,
                    ncell = length(grid1.wbnb$num),
                    cell = grid1$nearest_block_BBA_ID,
                    nsite = nrow(grid1),
                    forest = block$Forest1,
                    ncell_eb = nrow(coarse.block),
                    low = low,
                    high = high)


  
  #Set initial values
  car.inits <- function() {
    list(z = as.numeric(grid1$total.dets>0),
         alpha = runif(1,-1,1), 
         b.forest = runif(1, -1, 1), 
         S = rep(0, length(grid1.wbnb$num)),
         p = runif(1))
  }


  #parameters to monitor

  car.parameters <- c('psi', 'p', "alpha", 'b.forest')


  out <- bugs(data = car.data,
              inits = car.inits,
              parameters.to.save = car.parameters,
              model.file = here("Models/shared_with_cos.txt"),
              n.chains = nc,
              n.thin = nt,
              n.iter = ni,
              n.burnin = nb,
              bugs.dir = BD,
              working.directory = getwd(),
              debug = F)
