

There are no longer major problems with predictor collinearity, as all VIFs < 3.  Let us refit this as our starting model, and recalculate the residuals (as we will need them soon):
  
  ```{r}

## Refitting your starting model with the interactions back in:
startMod <- glm(formula = Resp ~ Cat + Cont1 + Cat:Cont1 + 1, # hypothesis
                data = myDat, # data
                family = Gamma(link = "log")) # error distribution assumption

summary(startMod) # a look at the model object

## Recalculate the residuals
simOut <- simulateResiduals(fittedModel = startMod, n = 250) # simulate data from our model n times and calculate residuals

myDat$Resid <- simOut$scaledResiduals # add residuals to data frame


```


Our starting model has now past the first hurdle to being considered wellspecified: no (significant) predictor collinearity.

# Considering observation independence


**What it is:**
  
  Many model fitting methods (including GLMs) assume that the individual observations (e.g. each row in your data frame) are independent from one another.  This means that the observations are not correlated (grouped) with one another in any way **except** as described in the predictors in your hypothesis. If this is true, each individual observation (row) can be called a replicate. When this assumption is violated, and you have observation dependence, it makes the estimate of your coefficients inaccurate, limiting the usefulness of your model.

Here is an example where you want to test the hypothesis that weight change is explained by food consumption (`WtChange ~ Food`);  

<img src="./indepViolationObserver.png" width="600px"/>
  
  Notice that `Observer` is not in your research hypothesis, but it is structuring your observations - the observations sampled by Betty are more similar than those sampled by Bob.  Without information about `Observer`, you will have a difficult time fitting the model to your data. Without the information about `Observer`, the "noise" of unexplained variation is high compared to the "signal" of the effect of `Food` on `WtChange`.


**How you know if you have a problem:**
  
  An easy way to tell if you have a problem is to plot your model residuals vs. any variable you suspect as being a source of dependence among your observations.  For example, highlighting `Observer` in the residuals with the example above:
  
  <img src="./findingDependenceIssues.png" width="600px"/>
  
  If `Observer` had no effect on `WtChange`, we would see no pattern in the colours of the residuals when plotted vs. `Observer`, but, instead, we see the colour of the residual points grouping together.  If you have a dependence problem in your model, you will see the "structure" in the unexplained variability (residuals).


## Types of observation dependence and what you can do about them

It is relatively common to find violations of this assumption^[also called pseudoreplication].  Violations can happen from:  
  
  * grouping of your observations by a variable not in your hypothesis^[also called nested sampling]

* observations that are made at different times (temporal autocorrelation)

* observations that are made at different locations (spatial autocorrelation)


### Grouping - a missing predictor

Grouping occurs when you have observations dependent on one another due to some other variable not in your hypothesis.  This may be a site variable (e.g. garden plots), or a variable that impacts your measurement (e.g. observer, or gear type), or could be related to repeated measurements (e.g. sampling the same individual multiple times).  

#### An example

<img src="./groupingEx.png" align="right" width="250px"/>
  
  Another example: you might be exploring the effect of added fertilizer on plant height with your hypothesis being `Height` ~ `Fertilizer`, with `Fertilizer` being a categorical predictor with levels of "Fertilized" or "Control".  In making your observations, you measure 24 plant heights growing in a Fertilized or Control site.  Oh, and these sites happened to be organized across six experimental plots.  

Given your hypothesis that `Height` ~ `Fertilizer`, each measurement of plant height will be treated as an individual observation (replicate) with the assumption that, other than the `Fertilizer` treatment, these observations are independent of one another.  However, this assumption is violated as the plants from the same plots may be more similar than plants from different plots (e.g. sunlight differences across plots may influence plant height, or water drainage differences across plots may influence the effect of the fertilizer).  The `Plot` variable may be grouping your observations.

<br clear="right"/>
  
  
  #### How you know if you have a problem with observations dependent based on a grouping variable
  
  You can find out if observation dependence is influencing your model by inspecting the residuals of your starting model.  Here, you plot your residuals vs. variables not in your model that may be causing dependence in the observations.  If you have a problem with observation dependence, there will be a pattern in your residuals when plotted against the offending variable.

Here is an example of how to do this with our generic example started above.  You can see how the residuals differ across levels of the `Other` variable also in our data set using violin plots: 
  
  ```{r}
ggplot()+ # start ggplot
  geom_violin(data = myDat,
              mapping = aes(x = Other, y = Resid))+ # add observations as a violin
  geom_point(data = myDat,
             mapping = aes(x = Other, y = Resid))+ # add observations as points
  xlab("Other variable")+ # y-axis label
  ylab("Scaled residual")+ # x-axis label
  labs(caption = "Figure 3: A comparison of model residuals vs. other variable")+ # figure caption
  theme_bw()+ # change theme of plot
  theme(plot.caption = element_text(hjust=0)) # move figure legend (caption) to left alignment. Use hjust = 0.5 to align in the center.

```

or with a points plot, by colouring the residuals based on the level in `Other`^[here I plot the residuals vs. `Cont1` but it could also be vs. the fitted values]:
  
  
  ```{r}
ggplot()+ # start ggplot
  geom_point(data = myDat, # the data frame
             mapping = aes(x = Cont1, y = Resid, col = Other), # add observations as points
             size = 3)+ # change the size of the points
  xlab("Cont1")+ # y-axis label
  ylab("Scaled residual")+ # x-axis label
  labs(caption = "Figure 3: A comparison of model residuals vs. other variable")+ # figure caption
  theme_bw()+ # change theme of plot
  theme(plot.caption = element_text(hjust=0)) # move figure legend (caption) to left alignment. Use hjust = 0.5 to align in the center.

```

Note that the spread of the residuals in each level (category) of `Other` is fairly equal in the violin plots and the colours are spread across the points plot.  This indicates that `Other` is not causing much structure in the residuals, and likely is not causing the model to violate the assumption of independence. 

Finally, if you quantitative evidence that your observations are dependent on your grouping variable, you can test to see if residuals among the different groups have similar variances.  This can be done with a Levene test for the homogeneity of variances through functions in the DHARMa package, e.g. 

```{r}


library(DHARMa) # load package

testCategorical(simOut, # the residuals 
                catPred = myDat$Other)$homogeneity # the grouping variable of concern

plotResiduals(simulationOutput = simOut, # compare simulated data to 
              form = myDat$Other, # our observations
              asFactor = TRUE) # whether the variable plotted is a factor



```

When your P-value is large (as it is here: P = `r round(data.frame(testCategorical(simOut, catPred = myDat$Other)$homogeneity)["group", "Pr..F."],3)`), you would say that there is no evidence that the residual variance depends on the levels in Other (i.e. no concern for observations being dependent on Other).

#### What can you do if your observations are grouped by something not in your hypothesis

If you find evidence of observation dependence, you can:
  
  **Add the grouping variable to your model as a (fixed effect) predictor:** The assumption of observation independence means that your observations are independent of one another in all ways *except for the predictors already included in your hypothesis*.  Therefore, an easy way to address observation dependence is to include the variable in your hypothesis, e.g. changing your original model:
  
  `Height ~ Fertilizer + 1`

to

`Height ~ Fertilizer + Plot + Fertilizer:Plot + 1`

would account for variability in plant height that was due to the plants growing in different plots (the main effect of `Plot`), as well as the influence of plot on the effect fertilizer has on the plants (the interaction `Fertilizer:Plot`).

Note that adding `Plot` in this way is adding `Plot` as a "fixed effect" (vs. "random effect" - more on this below).  In fact, every predictor we have been discussing up until now is in our model as something called a fixed effect.  

A couple of things to note when you add new fixed effects to your model: 
  
  1) Fixed effects influence the predicted mean of the model prediction, and so they are formerly part of your research hypothesis.  This means that your hypothesis changes every time you add or remove a fixed effect.  Your original hypothesis was

`Height ~ Fertilizer + 1`

or that variability in plant height is explained by fertilizer addition.  If you add `Plot` to your hypothesis to deal with observation dependence, your research hypothesis becomes:
  
  `Height ~ Fertilizer + Plot + Fertilizer:Plot + 1`

or that variability in plant height is explained by fertilizer addition, plot ID and the interaction between the two.

2) When you add new fixed effects to your hypothesis, your model gets more "expensive" to fit.  In the section on Hypothesis Testing, we will discuss how we can quantify the "benefit" of the model (increased explained deviance related to the likelihood of the model) vs. the cost of the model (how many coefficients have to be estimated).  Adding new fixed effects increases the cost of fitting your model as more coefficients need to be estimated.  This increased cost means you need bigger datasets (more observations) to fit the model.  When you add a new continuous predictor to your hypothesis, there is one more coefficient to estimate (in a linear model, this is a slope).  When you add a new categorical predictor to your hypothesis, you need to estimate another coefficient for each **level** in your new predictor.  In our example, you would need to estimate 6 - 1 = 5^[remember with categorical predictors, one factor level is included in the intercept] new coefficients to add the main effect of the `Plot` variable to the model, and another 6 - 1 = 5 coefficients to add the `Fertilizer:Plot` interaction to the model.

Both points above (that your hypothesis will change, and that your model will be more expensive to fit) means that just adding your grouping variable to deal with observation dependence is not always a great option. Instead you could,



**Add the grouping variable to your model as a random effect using a mixed model:** Many turn to mixed modelling as a way to deal with observation dependence.  Mixed modelling^[also called "multi-level modelling" or "hierarchical modelling"] is called "mixed" modelling because it includes a mix of both fixed effects (predictors that influence the model predicted mean) and random effects (predictors that influence the model predicted variance). Fitting mixed models is beyond the scope of this course, but I wanted you to have an idea of what mixed modelling is, and how to get started with mixed modelling, in case you want to use these methods in the future.  

To fit mixed models in R, you need to adjust your hypothesis formula to tell R which predictors should be treated as fixed and which should be random.    Recall that your model with only fixed effects:
  
  `Height ~ Fertilizer + Plot + Fertilizer:Plot + 1`

indicates that the predicted mean height is affected by fertilizer, plot ID and the interaction between the two, with separate coefficients associated with each plot ID.  In mixed modelling, you could instead include `Plot` with: 
  
  `Height ~ Fertilizer + (1|Plot) + (Fertilizer|Plot) + 1`

The `(1|Plot)` term will estimate one (not 5) extra coefficient describing how the variance in average height (the intercept) varies when you move from plot to plot.  The `(Fertilizer|Plot)` term will estimate one (not 5) extra coefficient describing how the variance in the effect of the fertilizer varies by plot.

So mixed modelling offers a way to address dependence in your observations that does not change your research hypothesis (as you are not adding fixed effects) and is cheaper (requiring less coefficient estimates as the random effects influence the modelled variance, not the mean).  

You can fit mixed models in the lme4 package using the `glmer()` function (which stands for Generalized Linear Mixed Effects Models, or GLMM), with syntax that is very similar to what we have been using for GLMs, e.g.

```{r eval = FALSE}
startMod <- glmer(formula = Height ~ Fertilizer + (1|Plot) + (Fertilizer|Plot) + 1,
                  data = myDat,
                  family = Gamma(link = "inverse"))
```

We won't explore this further here.

One final thing to note is that random effects will always be categorical.  If you have a continuous variable that is causing dependence in your observations, this variable can not be included as a random effect and must be included as a fixed effect.

Here is a table if you are trying to determine if a variable causing dependence in your model should be included as a fixed or random effect:

| Your situation                                                                                                                                                                    | Your choice       |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------- |
| - the variable causing dependence is continuous<br>- if you are interested in effect sizes of the variable on your response<br>- if the factor levels are informative (vs. just numeric labels)         | fixed effect<br>  |
| - the levels in the variable are only samples from a population of levels<br>- if you have enough levels (at least 5) to estimate the variance of the effect due to your variable | random effect<br> |

(adapted from Crawley2013TheRBook)



### Temporal autocorrelation

Temporal autocorrelation occurs when you measure your observations at different points in time. 

Observations collected closer together in time will be more similar than those collected further apart in time, and this could be happening independent of the mechanisms underlying your hypothesis.  This topic is beyond the scope of this course, but I add a short description here so the idea is "on your radar" as you move forward in biology.


#### An example


Suppose you want to test the hypothesis that variability in growth rate of newly hatched cod (torsk) in the Kattegat is explained by prey availability (`Growth` ~ `Prey`).  The observations you are using to test this hypothesis have been collected over ~15 years, and it is likely that measurements made closer to each other in time are more similar than those made further apart from each other in time.  This may be because the physical or biological environment was more similar in years that are close to each other in time (e.g. the parent population was similar, the temperature was similar)   However, there is nothing in your hypothesis (`Growth` ~ `Prey`) to let R know which observations are close to each other in time.  Thus, you violate the assumption of observation independence.

<img src="./TempAuto.png" align = "right" width="400px"/>


When a model is fit to data and the observations are dependent on their sampling time, similar values closer in time are given too much weight on the model coefficients and the model fit is biased (compare lines in the plot on the right).



#### How you know if you have a problem with temporal autocorrelation

You can find out if observation dependence due to temporal autocorrelation is influencing your model by plotting your model residuals vs. time.  If you have a problem with observation dependence, there will be a pattern in your residuals when plotted against the offending variable - in this case time.  

You can also determine how large the problem of temporal autocorrelation is by estimating the autocorrelation function^[e.g. using the `acf()` function in the base stats package in R] and the Durbin-Watson test.  An easy way to test the latter is with the `testTemporalAutocorrelation()` function in the DHARMa package. 


#### What you do if your observations are influenced by temporal autocorrelation

As above, the assumption of observation independence means that your observations are independent of one another in all ways *except for the predictors included in your hypothesis*.  We need to tell R about this temporal dependence in your model.  This can be done by including time as a predictor in your model.  Note that time will need to be a fixed effect as it is continuous, and will need to be modelled with a non-linear shape assumption^[we'll talk about non-linear models in a couple of weeks] to deal with the complicated form of the temporal autocorrelation.  

Alternatively, you can tell R about the correlation structure of the data directly (i.e. how similarity in observations changes as observations are further and further away from each other).<!--- need to give guidance here--->
  
  
  ### Spatial autocorrelation
  
  
  <img src="./SpatAuto.png" align = "right" width="400px"/>
  
  
  Similar to the previous section, spatial autocorrelation describes the dependence among observations that are collected at different spatial locations.  Observations measured close to each other in space are more (or less!) likely to be similar to one another than those measured further apart.  In the plot on the right you can see examples of observation dependence on space in the dispersed and clustered drawings.  In the dispersed example, observations closer to each other in space are **less** likely to resemble each other than one would expect if observations were distributed randomly in space (random example).  In the clustered example, observations closer to each other in space are **more** likely to resemble each other than one would expect if observations were distributed randomly in space.  

<br clear= "right"/>
  
  #### An example
  
  For example, you might be interested in how abundance of a species changes with mean environmental temperature and intend on testing the hypothesis that `Abundance ~ Temperature`.  Measuring abundance over a large spatial area, you find that observations made closer to each other in space are more similar than those measured farther apart and part of this is due to effects other than temperature (e.g. other aspects of the environment such as food availability are more similar to each other for sites that are closer together).  Without telling R information about where in space the observations were collected (remember, the hypothesis only includes `Temperature`), you violate the assumption of observation independence.

#### How you know if you have a problem with spatial autocorrelation

You can find out if observation dependence due to spatial autocorrelation is influencing your modelling by plotting your model residuals vs. location.  As location is measured in two dimensions, you could try a bubble plot^[check the sp package for more] or variogram^[check the sgeotest package for more] to help you look for patterns in your residuals with space.  You can also estimate how big the problem of spatial autocorrelation is with Moran's I test.  The last can be done with the `testSpatialAutocorrelation()` function in the DHARMa package.

#### What you do if your observations are influenced by spatial autocorrelation

Similarly to our discussion about temporal autocorrelation, the location of the observations (e.g. latitude and longitude) can be included in your model to account for the spatial autocorrelation^[this would be done with a non-linear model].  Alternatively, the dependence among observations due to proximity can be included in the model as a spatial autocorrelation structure.  <!---Again, this topic is beyond the scope of the course but check 9999.-->


### A final point about observation independence

Remember that you only have to worry about your observations being dependent based on variables not already in your hypothesis.    



# Considering your error distribution assumption

**What it is:** 

The error distribution (i.e. distribution of your residuals) needs to match the assumption you made when you chose your starting model.  If this assumption is violated, the estimates of your coefficients will be less accurate, limiting your ability to use the model to test your hypothesis and make predictions.  


<img src="./QQPlot.png" align="right" width="300px"/>
**How do you know if you have a problem:** 

You can compare the error distribution of your residuals with the distribution you expect given your error distribution assumption through something called a Q-Q plot.  A Q-Q plot - or quantile-quantile plot - plots the two data distributions against each other via their quantiles^[A quantile defines a particular part of a data set, e.g. the 90% quantile indicates the value where 90% of the values are less than the 90% quantile value.  See your notes DSPH_SM_DataDistributions.html for more].  When the expected and observed error distributions are in agreement, the points will fall along the red diagonal line in the Q-Q plot (the 1:1 line).  You can also help your interpretation of this by null hypothesis goodness of fits tests (more on this below).

The scaled residuals method introduced above will allow you to consider the behaviour of your residuals in a similar way regardless of the structure of your model.  You can get a Q-Q plot of your residuals with:

```{r}

# Consider your error distribution assumption by inspecting observed vs. expected residuals:

plotQQunif(simOut, # the object made when estimating the scaled residuals.  See section 2.1 above
           testUniformity = TRUE, # testing the distribution of the residuals 
           testOutliers = TRUE, # testing the presence of outliers
           testDispersion = TRUE) # testing the dispersion of the distribution



```

Note that the plot is the observed vs. expected scaled residuals.  As above, the triangular points will follow the red line in a well-specified model.  You will generally access this by eye, but the DHARMa package also includes three null hypothesis tests that give you more information about the behaviour of your residuals relative to the expected behaviour.  In all cases, a low P-value (traditionally P < 0.05) means that there is evidence that the null hypothesis can be rejected (and your error distribution assumption is not valid).^["Deviation n.s." on the plot means that there is no significant deviation from expected] 

The tests are:

* KS test:  The Kolmogorov-Smirnov test tests the null hypothesis that the distribution of your residuals is similar to the expected distribution (here, a uniform distribution). A low P-value means there is evidence that the observed residuals are different than expected, and your error distribution assumption is not valid.  You can also access this test directly with the `testUniformity()` function in the DHARMa package. 

* Dispersion test: This Dispersion test tests the null hypothesis that the dispersion of your residuals is similar to the expected dispersion. A low P-value means there is evidence that the observed dispersion is different than expected, and that your error distribution assumption is not valid.  You can also access this test directly with the `testDispersion()` function in the DHARMa package. 

* Outlier test: This Outlier test tests the null hypothesis that the number of outliers in your observed residuals is similar to the expected number. A low P-value means there is evidence that you have outliers.  You can also access this test directly with the `testOutliers()` function in the DHARMa package.  You can also find the position (row number) of the outliers with the `outliers()` function (also in the DHARMa package).




<br clear="right"/>



**What to do if it is a problem:**. 

Here are two examples (from the [DHARMA package vignette](https://cran.r-project.org/web/packages/DHARMa/vignettes/DHARMa.html)) of Q-Q plots where the error distribution assumption is not met:

<img src="./overDispersion.png" align="right" width="250px"/>
First, here is an example of overdispersion, where there are too many residuals in the tails of the distribution and not enough in the middle of the distribution when compared to the expected:^[Note that zero-inflated data (more zeroes than expected) appears similarly]

<br clear="right"/>


<img src="./underDispersion.png" align="right" width="250px"/>
Second, here is an example of underdispersion, where there are too many residuals in the middle of the distribution and not enough in the tails of the distribution when compared to the expected:

<br clear="right"/>

If your model residuals are not behaving as expected, you should first address any outlier problems.  Explore the observations labelled as outliers and see if they should be kept in your data set.  

Once you have explored outliers, if you still have residuals not behaving as expected, you can change your error distribution assumption and refit your starting model.  This may mean you change the link function you used to fit the model. The link function we have been using is always the default link function - which you can see at the help file with `?family`, but there are alternative link functions which can be used to help models that appear misspecified.  We will be discussing this in class.

Alternatively, you can try changing the actual assumption (e.g. trying a normal distribution instead of a Gamma distribution).  Note that with some types of response data (e.g. continuous) you have a number of different error distribution assumptions you can try (e.g. Gamma vs. normal), while others (e.g. binomial, presence/absence, etc.) are more limited.

In all cases, you will refit your model with the new assumption choice and re-validate that new model, as described here.  There will be times where you have tried everything and you still have evidence that your model is misspecified.  In these cases, look at the magnitude of the violation. 

If the violation appears minor (e.g. only a minor pattern in your residuals), your model *may* still be useable.  In such cases communicate the issue in your model validation assessment along with your attempts to correct it, and proceed with your hypothesis testing with a cautious eye.  We will discuss how to do this in class.

If the violation appears major, you may need to move on to another method (e.g. random forest or Bayesian design) that can help you design a more customized model to your situation. 




# Considering your shape assumption


**What it is:** 

You made an assumption about the shape of the relationship between your response and each predictor (e.g. a linear shape assumption).  You need to make sure that the assumption you made was useful before you can have the confidence in your coefficient estimates needed to proceed with the hypothesis testing.

**How do you know if you have a problem:** 

For this assumption, you need to look at how your residuals are scattered around your model fit.  If your model is a useful one ("wellspecified"), the scatter of those residuals will be even and uniform around the fit ("a uniform cloud").  You can inspect your residuals in this way by plotting the residuals vs. the fitted values.  

Here is code for this using the DHARMa package:

```{r}

plotResiduals(simOut, # the object made when estimating the scaled residuals.  See section 2.1 above
              form = NULL) # the variable against which to plot the residuals.  When form = NULL, we see the residuals vs. fitted values
              

```

This gives a plot of the scaled residual ("DHARMa residual") vs. the fitted values ("Model predictions"). Any simulation outliers (data points that are outside the range of simulated values) are highlighted as red stars.  You can use the `testOutliers()` and `outliers()` function in the DHARMa package to learn more about outliers.

Again, you are looking for a uniform cloud of points.  To help you assess the uniformity of the cloud, R adds quantile regression results: The three solid lines (called splines) are fit through the 0.25, 0.5 and 0.75 quantiles of the residual distribution.  Quantile regression compares the empirical 0.25, 0.5 and 0.75 quantiles of the residuals (solid lines) with the theoretical 0.25, 0.5 and 0.75 quantiles (dashed line), These lines are then compared with a quantile test that tests the null hypothesis that these splines are not different than the dashed horizontal lines.  If the null hypothesis of this is rejected, the curves will appear red in the figure, and you can determine your shape assumption was not valid.  

You should always inspect a plot of residuals vs. fitted values to explore your shape assumption.  If you have multiple predictors in your model, you should also plot the residuals vs. each predictor to make sure the shape you chose for each relationship is useful.  Here are the residuals of our example model vs. the `Cont1` predictor:

```{r}

plotResiduals(simOut, # the object made when estimating the scaled residuals.  See section 2.1 above
              form = myDat$Cont1) # the variable against which to plot the residuals.  When form = NULL, we see the residuals vs. fitted values
              

```


and vs. the `Cat` predictor:
```{r}

plotResiduals(simOut, # the object made when estimating the scaled residuals.  See section 2.1 above
              form = myDat$Cat) # the variable against which to plot the residuals.  When form = NULL, we see the residuals vs. fitted values
              

```
In this last figure, you get boxplots showing the distribution of the residuals - one for each level of your categorical predictor.  This different picture is because the predictor `Cat` is categorical.  Instead of a uniform cloud, you look for boxplots that spread across the 0.25 and 0.75 quantiles.  If the spread is wide and even across the levels of your categorical predictor, you have evidence the model is wellspecified to test your hypothesis.


<br clear="right"/>


**What to do if it is a problem:** 


Here is an example of a residual plot when you have a violation in your shape assumption^[from the [DHARMA package vignette](https://cran.r-project.org/web/packages/DHARMa/vignettes/DHARMa.html)]:


<img src="./violateShape.png" width="450px"/>


In this case, the predictor `Environment1` was fit with an assumption of a linear relationship with the response, when a non-linear shape assumption was needed.  Note that you can also access the quantile test used to flag shape assumption violations with the `testQuantiles()` function in the DHARMa package. 

If you find a pattern in your residuals that indicates a violation of your shape assumption, you can change your assumption and refit your model.  This may mean changing the shape of the model (e.g. from linear to non-linear) and/or including an interaction in your model.  

In all cases, you will refit your model with the new assumption choice and re-validate that the model is useful following the steps in this section.

# A final thought

As you can see, validating your starting model will sometimes lead you to make changes to your starting model that require you to refit your starting model and re-validate the new model  It can feel a bit like you are walking in circles, but rest assured that this is very normal.  And necessary: you can't go further to test your hypothesis until you are confident you have a useful model.


# Up next

In the next section, we will discuss how you can use your validated model to test your hypothesis. Finally: the science!
  
  
  
  
  