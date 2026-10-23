2

List of Figures
Figure 1

A diagrammatic overview of physic-based ground motion modelling in probabilistic seismic
hazard analysis. The flow diagram follows the path from the source model (whose
development is omitted for brevity), through the rupture selection process (Section 2.2),
rupture generation (Section 2.1.2), velocity model composition (Section 2.5), wave
propagation and intensity measure synthesis. The Graves & Pitarka (2010) hybrid
broadband method composes everything in the dashed line. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ⁠6

Figure 2

The source, path and site decomposition implied by Equation 2. The moment tensor
𝑴 (𝑡; 𝝃, 𝜏 ) describes the finite fault and how it slips and the Green’s function ∇𝑮 contains
the path and site terms. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ⁠7

Figure 3

The geometry of a planar finite fault. Strike angle 𝜑 a bearing measured from north and
has the range [0°, 360°]. The rake 𝜆 is a relative bearing in-plane with the fault describing
the direction of slip, it has angle between [−180°, 180°] – 𝜆 = 0° points in the direction of
strike. Dip direction is another bearing from north and is oriented to the right with respect
to strike. The dipping angle 𝛿 is measured from ground surface and has the range (0°, 90°].
Although dip direction is shown orthogonal to strike, it is not in general. . . . . . . . . . . . . . . . . . ⁠9

Figure 4

An illustration of the discretisation of a finite planar segment into square subfaults, and the
relation to the directions of 𝑢1 , 𝑢2 and 𝑢3 . The in-plane direction of 𝑢1 has azimuth equal
to the rake 𝜆, while 𝑢2 is in-plane and orthogonal to 𝑢1 and 𝑢3 is normal to the plane. . . . ⁠9

Figure 5

The high-level composition of slip, rise, rupture time and rake as the composition of
correlated and uncorrelated noise fields. Rake is independently drawn with the same
distribution parameters as slip, but is uncorrelated to it. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ⁠10

Figure 6

An illustration of the von Kármán correlation function using different isotropic correlation
lengths and Hurst exponents. As the correlation length increases slip is observed to have
larger scale structure on average. Large Hurst exponents smooth the small-scale
heterogeneity in the slip distribution. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ⁠11

Figure 7

The Cybershake New Zealand magnitude sampling function. Allocation is a function only
of magnitude, but is capped at both low and high magnitudes for a combination of
computational and representative reasons. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ⁠15

Figure 8

A hypothetical sampling logic tree. This model has two levels combining stakeholder
objectives in the first case, and sampling approaches in the second. The general case could
feature more branches or levels. The models and weights shown are illustrative. . . . . . . . . . ⁠16

Figure 9

The hybrid curvilinear and Cartesian discretisation used by SW4. Near the topography
𝑧 = 𝜏 (𝑥, 𝑦) a curvilinear mesh refinement is used that captures the topography faithfully
without a squashed or squashed-tapered approximation. SW4 also features mesh
refinements that iteratively reduce the grid spacing at depth where velocities are higher. . ⁠16

Figure 10 An illustration of the trade-offs present choosing between squashed, squashed-tapered, and
bulldozed topographic representation in a Cartesian velocity model. As is evident in the
squashed case, topography creates artificial impedance contrasts for depths below the
horizon (marked red). In the bulldozed case, both the near-surface weathering and basin
models (light blue) are truncated mean sea level. Squashed-tapered is a compromise to
represent the impedance contrast faithfully, but under represents topography to
compensate. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ⁠17
Figure 11 Point sampling against Backus averaging for a grid containing fine structure. In subplot (a)
the different representations of the 1D profile are shown. In subplots (b) and (c) a sectionview of the velocity model illustrates the effect Backus averaging has on basin edges. Note
that the point sample misses the low-velocity region between 0.5km and 0.75km while
Backus averaging approximates the band. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ⁠18

3

Figure 12 An overview of the design of the velocity model codebase. Grey boxes are implemented in
high-level Python, while computationally sensitive kernels are implemented in highperformance Rust to allow speed to buy velocity model complexity (e.g. Backus averaging,
which requires resampling the model several times). Dashed lines indicate modular
components of the software that are user-configurable and hot swappable. While under
internal testing at the moment, a release candidate will be made publicly available on
GitHub under an open source licence. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ⁠22
Figure 13 An early implementation of a mesh-native rupture generator applied to the Puysegeur
trench. This rupture was generated with mesh-aware slip and rupture onset time, and was
compared to a control method using a best-effort reproduction of the solve-and-project
approach. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ⁠23
Figure 14 Indicative timeline for the three objectives, in six-month periods. Timeline in the last six
months is indicative only. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ⁠25

4

1

Introduction
Physics-based probabilistic seismic hazard analysis involves the selection of ruptures from a source

logic tree, representation of those sources as finite fault models, and wave propagation through a
generated velocity model to target sites. Each of these components is challenged at present. The process
begins with the selection of scenarios from a rupture source model. The trend in source models is growing
complexity: The New Zealand National Seismic Hazard Model (NSHM) featured 536 characteristic
ruptures in its 2010 update (Stirling et al., 2012) but 7162 multi-segment and curved ruptures in the
most recent 2022 model (Gerstenberger et al., 2024a). Given the computational cost of simulating the
2010 model, millions core hours for simulations in Cybershake NZ 2010 (Bradley et al., 2019), more
sophisticated approaches are required to select a utility-maximising rupture set for multiple stake-holders
in engineering, surrogate modelling and scenario analysis. Once selected a source must be represented
as a finite fault model. To date, curved subduction models have been challenging to simulate within the
kinematic rupture modelling introduced by Graves & Pitarka (2010), due to the method’s restriction to
planar finite faults. Previous attempts have involved wrapping planar models around curved geometry
(Graves et al., 2011), but recent work highlights the effect curvature itself plays on hazard (Passone
& Mai, 2017). How seismic waves propagate from a source is determined by the velocity model. Here,
errors due to grid discretisation and topographic effects remain latent physics un-evaluated at scale in
validation. This thesis seeks to remedy these challenges through a novel framework for source model
sampling, development and evaluation of a new velocity model codebase incorporating scientific advances
in velocity modelling, and the generalisation of the kinematic modelling approach to curved subduction
interface earthquakes.

1.1

Objectives of this proposal

• Efficient estimation of seismic hazard using a source model logic tree sampling approach to hazard
sources.
• Enhanced velocity modelling including topographic effects, complex 3D basin models, and Backus
averaging.
• Kinematic modelling of subduction interface earthquakes incorporating curved geometry.

5

2 Background and Literature Review
The three objectives of this proposal are aimed at different parts of same process: estimating
probabilistic seismic hazard with physics-based ground motion models. An overview of the process is
shown in Figure 1 along with the areas of contribution for this thesis. Objective 1 concerns the sampling
of ruptures from source models, Objective 2 makes improvements to the representation of the 3D crustal
velocity model used in simulation, and Objective 3 extends the kinematic rupture generator used to
represent ruptures on a chosen source. This chapter outlines the relevant state-of-the-art in each area
and where gaps in literature remain.
Seismic source model
ruptures {rup𝑖 }, rates 𝜆(rup𝑖 )

Rupture selection
allocation 𝑁𝑖 over {rup𝑖 }
hybrid broadband simulation
Rupture realisation
kinematic rupture generator, 𝜽𝑗

3D velocity model
(𝜌, 𝑉𝑝 , 𝑉𝑠 , 𝑄)

Comprehensive
finite difference solution,
𝑓 < 𝑓max

Simplified
stochastic method,
𝑓 > 𝑓max

matched filter at 𝑓max and apply site amplification

Intensity measure at a site
I(IM > im | 𝜽𝑗 , site)
Monte Carlo over 𝑁𝑖 realisations
Hazard
𝜆(IM > im) = ∑𝑖 P𝑖 𝜆𝑖

Figure 1: A diagrammatic overview of physic-based ground motion modelling in probabilistic seismic hazard
analysis. The flow diagram follows the path from the source model (whose development is omitted for
brevity), through the rupture selection process (Section 2.2), rupture generation (Section 2.1.2), velocity model
composition (Section 2.5), wave propagation and intensity measure synthesis. The Graves & Pitarka (2010)
hybrid broadband method composes everything in the dashed line.

2.1

Hybrid broadband simulation of ground motion

Physics-based ground motion models predict ground motions by directly solving the equation
𝜌

𝜕2𝒖
= ∇ ⋅ 𝝈 + 𝒇.
𝜕𝑡2

6

(1)

A representation theorem for Equation 1 given a point source 𝝃 initiated at time 𝜏 expresses a
solution as a convolution of its source moment tensor 𝑴 (𝑡; 𝝃, 𝜏 ) with the Green’s function ∇𝑮(𝒙, 𝑡; 𝝃, 𝜏 )
governing wave propagation
𝒖(𝒙, 𝑡; 𝝃, 𝜏 ) = 𝑴 (𝑡; 𝝃, 𝜏 ) ∗ ∇𝑮(𝒙, 𝑡; 𝝃, 𝜏 ).

(2)

The right hand side of Equation 2 motivates the decomposition of ground motion at a site 𝒙 into
source, path and site effects. These effects are illustrated in Figure 2.
Source

Path

Site

𝑴 (𝑡; 𝝃, 𝜏 )

∇𝑮(𝒙, 𝑡; 𝝃, 𝜏 )

near-surface 𝑉𝑆 , basin

finite fault: slip, rise time, rupture

3D crustal structure

geometry and topography

time
𝒖(𝒙, 𝑡)

𝒙
basin

𝝃

Figure 2: The source, path and site decomposition implied by Equation 2. The moment tensor 𝑴 (𝑡; 𝝃, 𝜏 )
describes the finite fault and how it slips and the Green’s function ∇𝑮 contains the path and site terms.

Finite difference codes approximate a solution to Equation 1 in a finite domain 𝐷 by first discretising
it as a volume of 𝑁𝑥 × 𝑁𝑦 × 𝑁𝑧 gridpoints over a duration 𝑇 = 𝑁𝑡 Δ𝑡, iteratively computing a solution
over all gridpoints at each timestep. The general computation complexity of these methods for a fixed
domain 𝐷 and duration 𝑇 is of order 𝑂(𝑁𝑥 𝑁𝑦 𝑁𝑧 𝑁𝑡 ). One can relate these discrete parameters to the
simulation resolution ℎ by the relations 𝑁𝑥 , 𝑁𝑦 , 𝑁𝑧 ∝ ℎ−1 and the Courant–Friedrichs–Lewy stability
condition
Δ𝑡 ∝

ℎ
,
𝑣𝑝,max

(3)

so that the computational complexity of solving Equation 1 increases like 𝑂(ℎ−4 ). For a rigorous
approach to the theory of the seismic wave equation, one is directed to Aki & Richards (2002) and to
Moczo et al. (2014) for a treatment of finite difference schemes.
To accurately simulate ground motion up to a target frequency 𝑓max , a second governing equation
relates this to the shear-wave velocity 𝑉𝑆 , the resolution ℎ, and the number of gridpoints per shortest
wavelength 𝑃
𝑓max =

min(𝑉𝑆 )
.
ℎ𝑃

(4)

The parameters min(𝑉𝑠 ) and 𝑃 are typically fixed for physics and computational reasons, for instance
min(𝑉𝑠 ) = 500 m s−1 and 𝑃 = 5 (implicitly) in Bradley et al. (2019), or min(𝑉𝑠 ) = 500 m s−1 and 𝑃 = 8
in McCallen et al. (2024). Thus, as 𝑓max increases, the computational complexity of solving Equation 1

7

4
is of order 𝑂(𝑓max
). It is this last computational bound in terms of 𝑓max that motivates the introduction

of the hybrid broadband ground motion simulation method, as introduced in Graves & Pitarka (2010)
and subsequently updated (Graves & Pitarka, 2015; Graves & Pitarka, 2016; Pitarka et al., 2022). These
methods combine the comprehensive approach offered by finite difference codes for Equation 1 at low
frequencies, and a simplified approach (for example, Boore (2003)) at high frequencies. The frequency
𝑓max often plays the role of the transition frequency between the two domains. This section is an overview
of these methods and their use in earthquake engineering.

2.1.1

The Graves and Pitarka hybrid ground motion simulation method

The broad framework for the Graves and Pitarka simulation method, as introduced in Graves &
Pitarka (2010), consists of five key components:
1. A kinematic rupture generator incorporating spatial heterogeneity in slip, rupture speed and rise time,
2. The comprehensive approach to simulating ground motion at low frequencies through the use of finite
difference codes, most notably Graves (1996) and a 3D velocity model (e.g., Thomson et al. (2020)),
3. A simplified approach to ground motion at high frequencies,
4. The incorporation of site-specific amplification factors correcting for the discrepancy between simulation and target near-surface 𝑉𝑆 profiles and,
5. The combination of the above comprehensive and simplified approaches in the frequency domain
using a matched filter about a chosen transition frequency.
The general procedure is detailed in Baker et al. (2021, Ch. 5). Of most interest to this thesis is
the finite difference code, the 3D velocity model and kinematic rupture generator, and the validation of
the broadband method in the literature. This review shall now detail the latter two pieces to provide
background for the changes introduced in Objective 2 and Objective 3.

2.1.2

The Kinematic Rupture Generator

Moderate and large earthquake sources are modelled in the Graves and Pitarka method as finite
faults, a connected sequence of planar segments. Finite faults have a single dipping angle with respect
to the surface, and a dip direction oriented to the right with respect to a strike azimuth. The local strike
angle for each segment describes its plan-view bearing from north. The rake angle describes how the
fault moves in a rupture. These relationships are illustrated in Figure 3.

8

N

strike azimuth
ground surface
𝜑𝑠

strike

𝜆

𝛿
dip
slip vector

down dip

dip direction

fault plane

Section view

Plan view

Figure 3: The geometry of a planar finite fault. Strike angle 𝜑 a bearing measured from north and has the
range [0°, 360°]. The rake 𝜆 is a relative bearing in-plane with the fault describing the direction of slip, it has
angle between [−180°, 180°] – 𝜆 = 0° points in the direction of strike. Dip direction is another bearing from
north and is oriented to the right with respect to strike. The dipping angle 𝛿 is measured from ground surface
and has the range (0°, 90°]. Although dip direction is shown orthogonal to strike, it is not in general.

Finite faults are discretised into a number of subfaults (see Figure 4). These subfaults are themselves
double-couple point sources with a moment tensor 𝑴 and moment 𝑀0 . The moment tensor describes
shear forces due to slip at each subfault. Slip can be decomposed into a primary component 𝑢1 in-plane
in the direction of rake, 𝑢2 in-plane at a 90° angle to 𝑢1 , and 𝑢3 normal to the plane. In the special case
where 𝑢2 = 𝑢3 = 0, we have the double-couple moment tensor
𝑴=

0 0 𝑀0
0 0 0 .
𝑀
( 0 0 0 )

(5)

See Aki & Richards (2002) for the derivation of Equation 5 and its relation to the slip decomposition.
along strike (𝑥 km)

down dip (𝑦 km)

𝑢3
𝑢1

𝑢2

Δ𝑥 = Δ𝑦

Figure 4: An illustration of the discretisation of a finite planar segment into square subfaults, and the relation
to the directions of 𝑢1 , 𝑢2 and 𝑢3 . The in-plane direction of 𝑢1 has azimuth equal to the rake 𝜆, while 𝑢2 is
in-plane and orthogonal to 𝑢1 and 𝑢3 is normal to the plane.

In the Graves and Pitarka model a rupture is initiated at a point on the fault, the hypocentre,
and propagates over the surface. At every point four quantities describing the shape of the moment
release are recorded: total slip, total rise time, initiation time, and rake. The Graves and Pitarka rupture
generator is a kinematic rupture generator, by which we mean it generates slip using a noise distribution
shaped to empirically match source inversion models and correlates rise time with slip. The initiation

9

time is seeded with the solution to the Eikonal equation over the plane, and perturbed in correlation
again with slip. The rake angle is also drawn from a distribution centred on an input rake, but is not
correlated with slip. Slip, therefore, is the primary driver of the dynamics of the rupture model as shown
in Figure 5, and is worth elaborating on as its mathematics directly relates to Objective 3.

Figure 5: The high-level composition of slip, rise, rupture time and rake as the composition of correlated and
uncorrelated noise fields. Rake is independently drawn with the same distribution parameters as slip, but is
uncorrelated to it.

To generate slip as outlined in (Graves & Pitarka, 2010) and subsequently revised over the years
(Graves & Pitarka, 2016; Pitarka et al., 2022), we first describe the general shape of the noise distribution
that matches what we empirically observe from source inversions of finite fault models from historical
earthquakes (Frankel, 1991; Mai & Beroza, 2002; Somerville et al., 1999). In Mai & Beroza (2002) it is
observed that the noise is self-similar with a spectral distribution following the von Kármán correlation
function
𝐴(𝑘𝑠 , 𝑘𝑑 ) = √

𝑎𝑠 𝑎𝑑
(1 + 𝐾 2 )

𝐻+1

(6)

with 𝐾 2 = 𝑎2𝑠 𝑘𝑠2 + 𝑎2𝑑 𝑘𝑑2 a normalised wavenumber, 𝐻 the Hurst exponent describing the small-scale
roughness of the slip field, and 𝑎𝑠 and 𝑎𝑑 being correlation lengths along-strike and down-dip respectively.
Mai and Beroza fit 𝐻 = 0.75 and (log10 (𝑎𝑠 ), log10 (𝑎𝑑 )) ≈ (−2.5 + 12 𝑀𝑤 , −1.5 + 13 𝑀𝑤 ), but these are by
no means unique and subsequent studies fit different correlation lengths, notably for different tectonic
regimes (Melgar & Hayes, 2019; Skarlatoudis et al., 2016). The relationship between 𝑎𝑠 , 𝑎𝑑 , 𝐻, and the
distribution of the slip field is illustrated in Figure 6.

10

Figure 6: An illustration of the von Kármán correlation function using different isotropic correlation lengths
and Hurst exponents. As the correlation length increases slip is observed to have larger scale structure on
average. Large Hurst exponents smooth the small-scale heterogeneity in the slip distribution.

It should be appreciated that the spectral formulation of the von Kármán correlation function in
Equation 6 is a special case of the general Matérn kernel expressing covariance between two points 𝒖, 𝒗
in a metric space with distance 𝑑 as
𝐶𝜈 (𝑑) = 𝜎2

√
𝜈
21−𝜈 √
( 2𝜈 𝑑) 𝐾𝜈 ( 2𝜈 𝑑),
Γ(𝜈)

(7)

where 𝐾𝜈 is the modified Bessel function of the second kind of order 𝜈, 𝜎2 the variance of the
field, and 𝜈 > 0 the smoothness parameter. The spectral density of a Matérn field in ℝ2 satisfies 𝑆(𝒌) ∝
−(𝜈+1)

(1 + 𝐾 2 )

, so Equation 6 is recovered by setting 𝜈 = 𝐻.

Slip, and every subsequent field, is drawn from a Gaussian random field with the spectrum of
Equation 6. A tilde will denote the standardised form of a Gaussian field having zero mean and unit
variance, the final fields are scaled to appropriate physical parameters. For example, standardised slip 𝑢
̃
is shifted, truncated (to avoid negative slip) and rescaled so that 𝑀0 = ∫

𝑥∈𝐴

𝜇(𝒙)𝑢(𝒙) d𝐴, where 𝐴 is

the fault area, 𝜇(𝒙) and 𝑢(𝒙) local shear rigidity and slip, and 𝑀0 the target moment for the rupture.
The risetime field 𝜏 ′ is drawn from a noise field 𝜏̃ and is partially correlated with the slip field 𝑢
̃
(Pitarka et al., 2022) according to the relation
𝜏 ′ = 𝜌𝑢
̃ + √1 − 𝜌2 𝜏̃ .

(8)

The initiation time 𝑇 is determined by first solving the Eikonal equation in ℝ2
‖∇𝑇 (𝑥, 𝑦)‖ = 𝑠(𝑥, 𝑦)

(9)

with 𝑠(𝑥, 𝑦) being the slowness field being defined as the reciprocal of local shear-wave velocity 𝑉𝑆 .
The solution to the Eikonal equation provides physically consistent dynamics and the model perturbs
rupture time with another Gaussian field 𝑇 ′ drawn in the same way as risetime with correlation coefficient
𝜌𝑇 . In Equation 9 it is once again assumed that the finite fault is planar, but this restriction is not
necessary as the fast sweeping method (FSM) can be utilised (Qian et al., 2007) to solve the Eikonal
equation on a surface 𝒮︀
‖∇𝒮︀ 𝑇 (𝒙)‖ = 𝑠(𝒙).

11

(10)

As mentioned, the two key mathematical tools used to construct kinematic rupture models in the
Graves and Pitarka rupture generator are restricted in their present form to generating ruptures on
(a sequence of) finite planar segments. This limitation is challenging for simulations of megathrust
subduction events due to the typical curvature induced on the oceanic crust as it subducts under the
continental shelf. There are different techniques applied to get address curvature within the confines
of planar rupture generator, each with drawbacks. The first, employed in Graves et al. (2011) involves
generating the rupture parameters following the Graves and Pitarka method on a plane, and then
projecting the subfaults onto the curved structure. This preserves the geometry but, because the gradient
in Equation 9 and the spectral distribution in Equation 6 are naive to local curvature, both the correlation
lengths and local rupture speed are not faithfully mapped to the curved model. The impact of this
approximation remains under-studied. An alternative approach preserves the kinematic parameters by
adopting a source model that approximates the geometry as finite planar segments. This is the approach
taken in Dupuis et al. (n.d.). The cost of this approach is that the geometry can deviate substantially
from the curved model it approximates, this has impacts on source-to-site distances and hence the
accumulation of path effects. The impact of curvature on ground motion has been studied recently by
Passone & Mai (2017). Using a limited model for source curvature, Passone and Mai argue that curvature
itself contributes peak-ground velocity (PGV) amplifications factors in excess of two times higher than
a planar fault with the same moment. Passone and Mai do not create a curved rupture generator and
re-use the spectral von Kármán slip model. They isolate the effects of curvature from from path and site
effects using simulations in a uniform velocity model and ensembles of stochastic heterogeneous velocity
models and slip distributions. The scale of the fault model, a 𝑀𝑤 6.8 event with length 30 km and width
20 km is far smaller than what is found in the SLAB2 subduction interface geometries (Hayes et al.,
2018) or the Hikurangi and Puysegur trench geometries in the New Zealand Community Fault Model
(Seebeck et al., 2024). There is thus a gap remaining to implement the highlighted generalisations and
demonstrate the effects in scenario modelling of megathrust events.

2.2 Source rupture selection in probabilistic seismic hazard
analysis
Probabilistic seismic hazard analysis, formally introduced by Cornell (1968) and summarised in
Baker et al. (2021, Ch. 6), revolves around the calculation of Equation 11:
𝑛rup

𝜆(IM > im) = ∑ P(IM > im | rup𝑖 , site)𝜆(rup𝑖 ).

(11)

𝑖=1

Here 𝑛rup is the cardinality of a set of rupture scenarios {rup𝑖 } in a seismic source model, IM
an intensity measure of interest at a given site, and the exceedance probability 𝑃 (IM > im) is either
estimated using ground motion prediction equations (GMPEs) or physics-based ground motion models
(simulations). The variable 𝜆(rup𝑖 ) is the annualised rupture rate from the source model. Calculation of
the exceedance probability in the simulation context can be estimated using the Monte Carlo method
by simulating 𝑁sim (𝑖) realisations of inputs (capturing aleatory and epistemic uncertainties in ground
motion accumulating from source, path, and site terms) 𝜽𝑗 sampled from a joint distribution 𝜽,
𝑛rup

𝜆(IM > im) = ∑
𝑖=1

1
𝑁sim (𝑖)

𝑁sim (𝑖)

∑ I(IM > im | 𝜽𝑗 , site)𝜆(rup𝑖 ).
𝑗=1

12

(12)

Writing 𝜆𝑖 = 𝜆(rup𝑖 ) for the rupture rate, 𝑃𝑖 = P(IM > im | rup𝑖 , site) for the conditional
exceedance probability, and 𝑁𝑖 = 𝑁sim (𝑖), the Monte Carlo estimator of 𝑃𝑖 is 𝑃̂𝑖 = 1 ∑𝑁𝑖 I(IM >
𝑁𝑖

𝑗=1

im | 𝜽𝑗 , site), and its mean squared error is
2
𝑃 (1 − 𝑃𝑖 )
E[(𝑃̂𝑖 − 𝑃𝑖 ) ] = 𝑖
.
𝑁𝑖

(13)

̂ = ∑𝑛rup 𝜆 𝑃̂ for the hazard Λ = 𝜆(IM > im) is
Because realisations of rupture are independent Λ
𝑖=1 𝑖 𝑖
the sum,
𝑛rup

̂ − Λ)2 ] = ∑ 𝜆2 𝑃𝑖 (1 − 𝑃𝑖 ) .
E[(Λ
𝑖
𝑁𝑖
𝑖=1

(14)

From Equation 14 we can draw two general conclusions that frame this work: the difficulty in
estimating probabilistic seismic hazard is strongly dependent on how likely the rupture is to occur, and
proportional to how uncertain its contribution is to the PSHA sum.
Assuming that the sampling procedure input parameters Θ for a given rupture cannot be modified, it
is natural to consider stratified sampling using ruptures as our strata. The Neyman allocation (Rubinstein
& Kroese, 2008) provides the optimal sampling density for rupture strata 𝑁𝑖 ∝ (𝜆(rup𝑖 )𝜎(rup𝑖 )), where
𝜎(rup𝑖 ) is the standard deviation of 𝑃𝑖 = P(IM > im | rup𝑖 , site). While this equation is theoretically
optimal it has two practical issues:
1. Calculating 𝑁𝑖 requires knowing 𝑃𝑖 , which cannot be known without first running simulations.
2. The site and intensity measure dependence in 𝑃𝑖 means that the allocation is also site and intensity
measure dependent.
One can account for the site-dependence (resp. intensity measure) by averaging the site allocations
according to modeller determined weights, e.g., by population or areal coverage. A suitable surrogate
model, like an empirical ground motion model, could be used to provide a first-order estimate of 𝑃𝑖
and hence 𝑁𝑖 . Corrections may have to be made to account for the fact that the variance terms of the
empirical models don’t necessarily match the variance in simulations.
Examples of seismic source models include version three of the Uniform California Earthquake
Rupture Forecast (UCERF3) (Field et al., 2014) and the source logic tree in the 2022 revision of the
New Zealand National Seismic Hazard Model (Gerstenberger et al., 2024b). Both the UCERF and
NSHM models have undergone multiple revisions with a trend towards increasing source complexity. For
example, the 2010 revision of the NSHM (Stirling et al., 2012) considered only characteristic ruptures as
defined in Schwartz & Coppersmith (1984) with each fault source having a single fixed geometry, characteristic magnitude, and annual rate. The NSHM 2010 contains 536 fault sources (and hence characteristic
ruptures). The 2022 revision of the model, however, uses an inversion method (Gerstenberger et al.,
2024a) that produces 7,162 ruptures with an mean annual rate 𝜆(rup𝑖 ) > 0, and models both multisegment crustal and curved subduction interface ruptures.

13

Tectonic regime

Faults

Ruptures

Rate > 0

Share

𝑀𝑤 range

Hikurangi–Kermadec interface

452

23,675

1,645

6.95%

7.55–9.60

Puysegur interface

271

15,800

1,633

10.34%

7.05–8.78

Crustal faults

2,325

411,270

3,884

0.94%

6.90–8.54

Total

3,048

450,745

7,162

1.59%

6.90–9.60

Table 1: Ruptures in the 2022 New Zealand National Seismic Hazard Model source model, by tectonic regime.
Only 1.59% of the 450,745 ruptures in the inversion rupture set carry a non-zero annual rate. The 𝑀𝑤 range
is quoted over ruptures with a non-zero rate.

Each evaluation of the indicator function I(IM > im | 𝜽𝑗 , site) in Equation 12 represents the output
of one simulation measured at a given site. In the forward simulation method, using codes such as
EMOD3D, intensity measures can be computed for a single rupture at all sites simultaneously. Large-scale
studies such as CyberShake NZ (Bradley et al., 2019) using the NSHM2010 model consumed millions of
core-hours to estimate 𝑃 (IM > im) at 27,481 sites using 11,362 rupture realisations. The 2019 CyberShake study simulated realisations at a discretisation of ℎ = 400 m with a target resolvable frequency
of 𝑓max = 0.25 Hz. Under a 𝑂(ℎ−4 ) scaling assumption we can estimate that the cost of conducting the
same study at ℎ = 100 m, to be of the order of hundreds of millions of core-hours. Naively sampling all
ruptures the NSHM 2022 model only once, the order of magnitude required for a ℎ = 100 m CyberShake
New Zealand hazard estimate using the NSHM 2022 source is therefore on the order of billion core-hours.
By comparison, the largest allocation available through a EuroHPC Regular Access call is approximately
800,000 CPU node-hours per cut-off (Eurohpc JU Call for Proposals for Regular Access Mode, n.d.),
equivalent to roughly 90 million core-hours on the general purpose partition of the MareNostrum 5 preexascale system (Marenostrum 5 Technical Information, n.d.), so clearly a naive 100 m CyberShake is
computationally infeasible on current hardware. We thus arrive at the central computational problem
calculating PSHA by the Monte Carlo method for simulations: How do we allocate a relatively small
core-hour allocation over a set of ruptures in a seismic source model to efficiently reduce the error in
estimated hazard when using the Monte Carlo method in forward simulation of ground motion?

2.3

Prior rupture sampling work

Large-scale use of simulations in PSHA has two examples:
1. State-wide California Earthquake Centre (SCEC) CyberShake. SCEC CyberShake
(Callaghan et al., 2024; Graves et al., 2011) performs PSHA on the UCERF family of source models
within the Graves and Pitarka hybrid ground motion methodology. It diverges from CyberShake New
Zealand in that SCEC works with the reciprocity model, which applies source-receiver reciprocity
in the Green’s function to make the number of sites the dominant factor in compute cost instead
of ruptures. Still, SCEC does apply a rupture sampling methodology based on fault area (Statewide
California Earthquake Center, 2020). For each site all ruptures within 300km are considered, and then
each rupture is sampled with a equally spaced set of hypocentre’s 4km apart. This in effect means
𝐴
that the ruptures are sampled in direct proportion to area with 16
ruptures for a fault with area 𝐴.

2. New Zealand CyberShake. Modelled on the SCEC example, New Zealand CyberShake (Abbasnejardfard et al., 2024; Abbasnejardfard et al., 2025; Bradley et al., 2019) differs to SCEC in primarily
using the forward simulation methodology where additional stations are cheap and ruptures dominate

14

the compute cost. A to-appear version of New Zealand CyberShake samples ruptures using a piecewise

realisations per rupture, 𝑁

function of magnitude, sketched in Figure 7. New Zealand CyberShake uses the NSHM source model.

68
𝑁 = 27𝑀𝑤 − 148

14

6

7

8

9

moment magnitude 𝑀𝑤

Figure 7: The Cybershake New Zealand magnitude sampling function. Allocation is a function only of magnitude, but is capped at both low and high magnitudes for a combination of computational and representative
reasons.

Both sampling methods are blind to the potential impact of a simulation. In the New Zealand
CyberShake model a 𝑀𝑤 8 in a hazard-sensitive location Wellington is sampled exactly as many times
as a 𝑀𝑤 8 rupture in Fiordland.

2.4 Stakeholders in rupture sampling: extending beyond a
hazard-only context
While CyberShake is primarily designed for use in PSHA, other users of the data have different
needs that should be considered. Machine learning surrogate modelling is one example with a symbiotic
relationship to PSHA in light of the Neyman allocation in Equation 14. While PSHA would ideally
only sample hazard relevant ruptures, machine learning can be sensitive to class imbalance (Johnson
& Khoshgoftaar, 2019) which means that a uniform sampling of magnitude and source-site distances
may be preferable – as evidence in recent Cybershake-style studies in Iceland (Blanco-Prieto et al.,
2026). Meanwhile, subsets of CyberShake simulations could be used for scenario modelling, and so
oversampling for hazard may mean limiting the scope for future re-use of work. In light of the considerable
computational cost, it is therefore prudent to consider the rupture sampling problem in a multi-objective
sense: How do we allocate a relatively small core-hour allocation over a set of ruptures in a seismic source
model to maximise multi-objective stakeholder utility when using the Monte Carlo method in
forward simulation of ground motion?
The allocation of weights to different outcomes is subjective rather than objective. In such cases
where models with epistemic uncertainty or choices with subjectivity are concerned, it is usual to consider
a logic tree framework (Baker et al., 2021, Ch. 6). The source model underlying the NSHM is an example
of a source logic tree, and the hazard estimates provided in the NSHM come from a logic tree of empirical
ground motion models. In both cases a combination of empirical measurements and modelling choices
determine the weights assigned to each model considered. A natural extension then is to consider the
question of rupture sampling itself with a sampling logic tree. Such a sampling logic tree would combine
independent models optimised for different stakeholder objectives, and combined under a combination
of epistemic and modeller determined weights as in the source logic and ground motion logic trees.

15

stakeholder objective

Hazard
estimation

allocation model

𝑤11

Neyman allocation, 𝑁𝑖 ∝ 𝜆𝑖 𝜎𝑖

𝑤12

rate-proportional, 𝑁𝑖 ∝ 𝜆𝑖

𝑤1
Rupture sampling
allocation 𝑁𝑖
𝑤2

uniform in (𝑀𝑤 , 𝑅rup )
Surrogate model
training

𝑤3

𝑤21
𝑤22
space-filling design over 𝜽

𝑤31

Scenario
re-use

fixed scenario set, 𝑁𝑖 prescribed

Figure 8: A hypothetical sampling logic tree. This model has two levels combining stakeholder objectives in
the first case, and sampling approaches in the second. The general case could feature more branches or levels.
The models and weights shown are illustrative.

2.5 Topographic modelling and Backus averaging in velocity
models
Topographic effects have been extensively studied in observation (Geli et al., 1988). Topography
affects the simulation of ground motion in two ways:
1. Topographic amplification effects. Topographic amplification refers to the concentration of seismic
energy along areas of high topographic index such as steep cliffs and ridges (Geli et al., 1988).
Correctly simulating the effects of topographic amplification requires a wave propagation code aware
of the geometry. Finite difference codes like SW4 (Petersson & Sjögreen, 2015) have employed hybrid
curvilinear and cartesian meshgrids to model topography in the near-surface with efficient Cartesian
update stencils at depth as shown in Figure 9.
2. Displacement of near-surface velocities. A flat free-surface means that a modelling decision must be
made about to represent surface velocities above and near sea level. Shifting or removing the velocities
above sea level can significantly change the representation of small scale near-surface features such
as sedimentary basins.
𝑧 = 𝜏 (𝑥, 𝑦)
Curvilinear grid,
topography-conforming

grid interface
Cartesian grid,
cheap update stencil

ℎ

Figure 9: The hybrid curvilinear and Cartesian discretisation used by SW4. Near the topography 𝑧 = 𝜏 (𝑥, 𝑦)
a curvilinear mesh refinement is used that captures the topography faithfully without a squashed or squashedtapered approximation. SW4 also features mesh refinements that iteratively reduce the grid spacing at depth
where velocities are higher.

16

In Thomson et al. (2020), building on prior work on topographic modelling (Aagaard et al., 2008),
three approaches to near-surface velocities are considered. These approaches are squashing (shifting) the
topography down, bulldozing the topography (ignoring velocities above sea level), and squashing topography to a fixed horizon with velocities unchanged underneath. These three approaches are illustrated
in Figure 10, alongside the true medium they approximate.

Figure 10:

An illustration of the trade-offs present choosing between squashed, squashed-tapered, and

bulldozed topographic representation in a Cartesian velocity model. As is evident in the squashed case,
topography creates artificial impedance contrasts for depths below the horizon (marked red). In the bulldozed
case, both the near-surface weathering and basin models (light blue) are truncated mean sea level. Squashedtapered is a compromise to represent the impedance contrast faithfully, but under represents topography to
compensate.

Recent work using SW4 showcased in McCallen et al. (2024) demonstrates that finite-difference
codes with similar performance characteristics to traditional cartesian grid approaches are ready for largescale simulations. To date, no extensive study of validation in of the effect of topography in simulations
against observed ground motions in the style of Lee et al. (2020) has been undertaken, though previous
works (Stone et al., 2022) have been completed on a smaller scale.

2.5.1

Backus averaging

In velocity modelling codes like Thomson et al. (2020) a single point is queried at each depth for
a tuple of material properties (𝜌, 𝑉𝑝 , 𝑉𝑠 ), with 𝜌 the material density and 𝑉𝑝 , 𝑉𝑠 p-wave and s-wave
velocities respectively. The velocity is then assigned to the entire cell; a point at depth 𝑧 in a simulation

1
The exact details of the spacing depends on the discretisation scheme. The NZVM code in Thomson et al. (2020) is
designed for EMOD3D (Graves, 1996). EMOD3D uses this scheme at all depths except the free-surface where a velocity
at the surface represents velocities to a depth of ℎ2 km.

17

with resolution ℎ km represents velocities to a depth 𝑧 + ℎ km1. Being only a point-estimate of the
velocity at 𝑧 km means the velocity model is subjective to an idiosyncratic sampling bias.
Backus averaging addresses the point-estimate error by supersampling. Instead of sampling for a
velocity at 𝑧 km, we sample 𝑁 points equally spaced between 𝑧 km and 𝑧 + ℎ km and average the
qualities based on the material moduli equations
2

𝜇𝑖 = 𝜌𝑉𝑠 (𝑧 + 𝑖
𝜇⋆ =

2

ℎ
)
𝑁

𝜆𝑖 = 𝜌𝑉𝑝 (𝑧 + 𝑖

1 𝑁−1
∑𝜇
𝑁 𝑖=0 𝑖

𝜆⋆ =

𝜇⋆
𝜌

𝑉𝑝⋆ = √

𝑉𝑠⋆ = √

ℎ
) ,
𝑁

1 𝑁−1
∑𝜆,
𝑁 𝑖=0 𝑖

(15)

𝜆⋆
.
𝜌

The anelastic attenuation parameters 𝑄𝑝 and 𝑄𝑠 which are the inverse of the energy lost in a cycle
must be averaged harmonically,
𝑄𝑝⋆ =

1 𝑁−1
1
∑
,
ℎ
𝑁 𝑖=0 𝑄𝑝 (𝑧 + 𝑖 𝑁
)

1 𝑁−1
1
𝑄𝑠⋆ =
∑
.
ℎ
𝑁 𝑖=0 𝑄𝑠 (𝑧 + 𝑖 𝑁
)

(16)

Backus averaging allows small-scale near surface structure to be approximated when ℎ is large
relative to the feature size, where a point sample may miss the feature entirely (Figure 11).

Figure 11: Point sampling against Backus averaging for a grid containing fine structure. In subplot (a) the
different representations of the 1D profile are shown. In subplots (b) and (c) a section-view of the velocity
model illustrates the effect Backus averaging has on basin edges. Note that the point sample misses the lowvelocity region between 0.5km and 0.75km while Backus averaging approximates the band.

Similarly to topography, no large-scale validation in the style of Lee et al. (2020) has been undertaken
to date.

18

3

Research Objectives

3.1

Objective 1: Source rupture selection

This objective concerns source the rupture selection problem in PSHA as describe in Section 2.2. It
addresses the following question,
Objective 1: Central Question
How do we allocate a relatively small core-hour allocation over a set of ruptures in a seismic source
model to efficiently reduce the error in estimated hazard when using the Monte Carlo method in
forward simulation of ground motion?
The deliverable of this objective would be a methods paper outlining the application of a sampling
logic tree to the multi-objective optimisation problem of rupture source selection. This paper would
explore modelling considerations in designing the logic tree, and an illustration of their impact on source
selection and hazard estimation. The methods outlined are being employed in upcoming iteration of
CyberShake NZ on the NSHM 2022 source model, and would act as a large-scale demonstration of the
technique.

3.2 Objective 2: Validation of topographic modelling and
Backus averaging
This objective concerns the impact of two key advancements in the velocity model used in finite
difference codes: topographic modelling and Backus averaging. While both have been used in simulations
before, and topographic effects are well understood in observations, neither has been validated at scale
under a MERA framework similar to Lee et al. (2020).
Objective 2: Central Question
What are the effects of topography and Backus averaging in physics-based ground motion models
following the Graves and Pitarka method using SW4?
In answering this question, a new velocity model code must be developed that can handle curvilinear
models and super-sampling required for Backus averaging. This velocity model code will also incorporate
a modular software design, support complex 3D basin and tomography models and be available for use
by researchers globally. This therefore positions the software component of this objective as an update
to an earlier version the NZVM, published in Thomson et al. (2020). We thus have two deliverables for
this objective:
1. A paper focussing on the implementation and documentation of the new velocity model codebase,
with a similar scope to Thomson et al. (2020). A software package would be made available on GitHub
and as a Zenodo object for further citation by researchers using the work.
2. A paper applying the new features enabled by the software to evaluate the effects of topography and
Backus averaging under a MERA framework.

19

3.3 Objective 3: Kinematic rupture generation on mesh
geometry
The aim of this objective would be to generalise the work of Graves & Pitarka (2010); Pitarka et
al. (2022) to generatic kinematic ruptures on arbitrary mesh geometry, such as is commonly modelled
for subduction interfaces in the SLAB2 database (Hayes et al., 2018), the New Zealand Community
Fault Model (Seebeck et al., 2024) and implemented in source models like the 2022 revision of the
New Zealand National Seismic Hazard Model (Gerstenberger et al., 2024b) and the Uniform California
Rupture Forecast version three (Field et al., 2014). We would then aim to evaluate this new generator
in scenario modelling of a Hikurangi megathrust event with similar parameters to Dupuis et al. (n.d.)
to at least partially answer the following question:
Objective 3: Central Question
What role does interface curvature play in the ground motion intensity for megathrust subduction
events, such as a hypothetical Hikurangi-Kermadec rupture?
To address this question, and like Objective 2, we must also develop a new rupture generator
employing the mathematics detailed in Section 2.1.2. This rupture generator would also incorporate the
multi-segment rupture generation method outlined in Bradley & Faulkner (2026), with a design aimed
to be utilised by other researchers. The deliverables of this objective are:
1. A paper focussing on the implementation and documentation of the new rupture generator, similar
to paper one of Objective 2,
2. A scenario paper with similar scope to Dupuis et al. (n.d.) using the new rupture generator to observe
the effect of curvature in hypothetical mega-thrust scenarios.

20

4

Progress to Date

4.1

Objective 1

Objective 1 began by incrementally introducing complexity into the rupture sampling schemes.
Initially, only a single site and intensity measure was considered to remove the consideration of averaging
rupture profiles. It was observed that the Neyman allocation offered strong variance reduction in the
single-site single-IM case, as theory requires, and so the scope was gradually expanded to include first
multiple sites, then multiple intensity measures, and finally to tackling the complete complexity of a
weighted sampling logic tree as proposed. At this stage a prototype logic tree has been developed based
on the hazard estimation branch only with a combination of rate-proportional allocation and Neyman
allocation. A deliberate choice was made to separately weight subduction and crustal tectonic samplings
under the observation that considering them both together overweighted Hikurangi and Puysegeur
ruptures due to the generally higher epistemic uncertainty in the GMPEs used to build the sampling
densities (as opposed to a genuine reflection of their uncertain contribution to hazard).
The results for this objective are currently underway in an iteration of Cybershake presently
underway on the Mare Nostrum 5 cluster. Results are anticipated early next year, at which point
bootstrapping will be applied to the sampling to address counterfactual Cybershake runs with different
weights without re-running all the calculations again.

4.2

Objective 2

Objective 2 has to-date focussed on the software implementation of a updated velocity model
codebase. The design is intentionally modular and location-agnostic to give it the best chance of wide
adoption in the community (see Figure 12). The prototype was completed in May and June and since
then extensive validation studies have been undertaken to verify the combination of the new velocity
model and SW4 against the established EMOD3D workflow typified in Lee et al. (2020).

21

Command-line interface
subcommands, syntax-highlighted config errors,
live progress and resource reporting

Configuration
TOML, YAML or JSON; sections tagged by type
and validated field-by-field

Grid definitions
chosen by config type

Query pipeline
continuation-passing chain

regular · emod3d · sw4

query ▸ backus ▸ ely ▸ … ▸ ⊥

Chunked execution
one pass per grid; each layer sees a concrete chunk
point queries
Rust kernels (PyO3)
mesh and surface queries, priority-tree blending

Output formats
EMOD3D · SW4 · compressed store

Figure 12: An overview of the design of the velocity model codebase. Grey boxes are implemented in high-level
Python, while computationally sensitive kernels are implemented in high-performance Rust to allow speed to
buy velocity model complexity (e.g. Backus averaging, which requires resampling the model several times).
Dashed lines indicate modular components of the software that are user-configurable and hot swappable.
While under internal testing at the moment, a release candidate will be made publicly available on GitHub
under an open source licence.

4.3

Objective 3

Objective 3 is the least mature objective, but still progress has been made. The internals of Genslip
have been studied, the results of which are shown in Section 2.1.2. The generalisations outlined there have
been prototyped and curvilinear mesh ruptures have been generated (Figure 13). Preliminary results
indicate that the effect of curvature is not prominent in the representation of the source in realistic
profiles that are present in subduction interface geometries like the Puyseguer trench and Hikurangi
subduction zone. Without conducting simulations the results cannot be verified, and this will be a key
objective of the next few months. Assuming that curvature continues to play a less prominent role than
previously assumed the focus of the objective will be toward improving and systematising the planar
projection approach in Graves et al. (2011) coupled with the multi-segment rupture generator of Bradley
& Faulkner (2026). This is preferred over a mesh native approach because the code is much simpler and
therefore easier to validate. Also implemented in the planar case are mathematical improvements to the
slip and rupture time quantities: an exact von Karman sampler using the circulant embedding method
(Dietrich & Newsam, 1997) and a second-order accurate factored Eikonal solver (Fomel et al., 2009)
that handles the singularity imposed by the hypocentre and is tolerant to infinite slowness fields used
to mask out the bounds of non-convex subduction geometries.

22

Figure 13: An early implementation of a mesh-native rupture generator applied to the Puysegeur trench. This
rupture was generated with mesh-aware slip and rupture onset time, and was compared to a control method
using a best-effort reproduction of the solve-and-project approach.

23

5

Resources
This work will not have any field-testing component or the use of labs or experiments. However,

extensive use of computer resources will be required. To date, the following research compute clusters
have been used:
• The University of Canterbury Research Compute Cluster (RCH), provided generously without corehour allocation. This is primarily used for the testing of models and internal results.
• An early-access preview of Earth Sciences New Zealand’s Cascade compute cluster. This cluster is
also provided a without core-hour allocation limit at present.
• The Barcelona Computing Center’s MareNostrum 5. Compute for this cluster is provided for an
allocation period ending in December 2026, with the sampling strategies for Objective 1 being trialled
on the cluster.
In addition, the following compute resources may also be used if required:
• The Texas Advanced Compute Cluster (TACC), for which we already have an allocation ending in
September 2026.
• The REANNZ HPC3 compute cluster.
Given the range of redundant options available it is the view of the author that access to compute
should not be a major risk in the completion of any of the objectives outlined. In addition, the scope of
the computationally intensive proposed work in Objective 2 and Objective 3 can easily be scaled back
without compressing the novelty of the research if required.
Data used for the projects consists of publicly available releases of source models, notably the NSHM
source model and the New Zealand community fault model – used in Objective 1 and Objective 3. Data
generated in the course of research will be archived on Dropbox and, if appropriate, released separately
on field-appropriate archives like DesignSafe CI (Rathje et al., 2017) or Zenodo for smaller objects and
software releases. In this way both research and data will be citable and trackable across future updates.
Code for both the rupture generator and velocity model will be published on GitHub under the ucgmsim
organisation when ready for release. Research, code, internal figures and data are regularly backed up
on Dropbox and version controlled in GitHub where appropriate.

24

6

Proposed Timeline
Jun – Dec 2026

Jan – Jun 2027

Jun – Dec 2027

Objective 1
Source rupture selection

CyberShake simulation on
MareNostrum 5

Processing of CyberShake results

Publication of results

Objective 2
Topography and Backus
averaging

Internal testing; validation
against observation

Validation suite with and without
topography and Backus averaging
(Cascade)

Draft and publication

Objective 3
Rupture generation on mesh
geometry

Continued prototyping of curved
rupture models

Experimental design for
Hikurangi scenario simulations

Execution of simulations

Jan – Jun 2028

thesis
composition

Publication of results

Figure 14: Indicative timeline for the three objectives, in six-month periods. Timeline in the last six months is indicative only.

25

