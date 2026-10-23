# Towards 2 Hz: topography, variable mesh refinement and modular velocity models for physics-based ground motion simulation

Previous iterations of Cybershake NZ made two compromises in the near surface,
where basin and site effects matter most. The finite-difference grid was
uniform, so resolving low-Vs sediments was too expensive and the transition
frequency was held at 1 Hz. The free surface was flat, so topography was
squashed or bulldozed into the velocity model. This talk explores a series of
changes to our physics-based ground motion modelling that remove these
compromises, and the software that architects them.

We adopt the SW4 finite-difference code, which uses variable mesh refinement to
concentrate resolution in the near surface and models topography explicitly on
a curvilinear mesh. Together with our performance improvements to SW4, this
makes a 2 Hz transition frequency and a lower minimum Vs affordable.

To drive SW4 we have rebuilt the velocity model codebase. The new code is a
small core that assembles tomography, basin and geotechnical models from
configurable data, so researchers can plug in, replace and dynamically extend a
model without touching the code. It also enables supersampling via Backus
averaging, so SW4 sees thin layering in basins and the near surface as an
effective medium instead of aliasing it onto the grid.

We are now running this workflow over a validation set of moderate (Mw 5-6)
crustal events in the New Zealand ground motion database (GMDB). We compare the
results with our previous workflow using mixed-effects residual analysis,
looking at changes in bias and in between-event, site-to-site and within-site
variability. We present early results from the recent Mw 5.7 Taumarunui event.
The talk ends with the questions the full dataset should answer.
