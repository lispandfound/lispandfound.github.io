Reproducible and usable scientific data at scale
lessons from Cybershake and validation research
Jake Faulkner
30 August 2026
University of Canterbury

We already agree on this

F

A

I

R

Findable

Accessible

Interoperable

Reusable

it has an identifier
somebody can search

they can retrieve it
without asking you

their software opens it
without your code

it says what it is,
and how it was made

Wilkinson et al. (2016). Nobody argues with it. Almost nobody does it.

1 / 12

What we say instead

“It is too much work.”

“My data is too big for that.”

“Nobody would use it anyway.”

“I will put it up if somebody asks.”

2 / 12

Three of those are testable

Colavizza et al. (2020), PLOS ONE. 531,889 articles, three-year citation window.

3 / 12

“My data is too big”

51,895

sites, in this one earthquake

81

events in the validation set

293

ruptures in the Cybershake pilot

A full Cybershake is tens of thousands of
simulations. Big has never been the
reason.
4 / 12

We were terrible at this

A box of code

tar czf

Dropbox

cluster modules,
hard-coded paths, one shell

one archive per
campaign, per version

215 TB,
18,349 tarballs

The largest single tarball is 370 GB.
Outsiders could not use this. Neither could we.

5 / 12

Five changes

Pin the
environment
a container

Publish the tools
a package index

Let the data
describe itself

Keep the recipe
with the result

Make it queryable,
not browsable

NetCDF

one JSON file

a database

Read the top line of each box. The technology underneath is only what we chose.

6 / 12

Pin the environment

runner.sif one file, 1.7 GB

Ubuntu + system libraries
Python

Still the host’s
apt

3.13.12

Our six packages

pinned to a commit

EMOD3D source tools

genslip, srf2stoch

The MPI solvers. They link
the machine’s own network
fabric, and nothing portable
can.

Built from a recipe in version control, tagged with the commit it was built from.

7 / 12

Publish the tools

Last 30 days, from the public package index. Nobody asked us for any of these.

8 / 12

Let the data describe itself

<xarray.Dataset> Size: 10MB
Group: /PGV
Dimensions:
(station: 51895)
Coordinates:
* station
(station) <U7
'ADCS' 'AICS' ... 'rvpcATA'
latitude (station) float32 [deg] -43.90 -42.77 ...
rrup
(station) float64 [km]
173.8 47.55 ...
rjb
(station) float64 [km]
171.2 45.90 ...
vs30
(station) float64 [m/s] 431.0 299.0 ...
z1pt0
(station) float64 [km]
0.1781 0.3156 ...
Data variables:
000
(station) float64 [cm/s] 0.2937 0.4598 ...
090
(station) float64 [cm/s] 0.2507 0.8212 ...
ver
(station) float64 [cm/s] 0.1144 0.1146 ...
rotd50
(station) float64 [cm/s] 0.2701 0.6205 ...
Attributes:
name:
PGV
description: Peak ground velocity

NetCDF. The format atmospheric
science has used for thirty years.
Opens in MATLAB, R, Python and
ArcGIS today, with no code of
ours.
The distances, the site terms and the
units are in the file. Nobody has to
be told.

9 / 12

Keep the recipe with the result

realisation.json

one text file, 23 sections, 55 kB. The entire input to the run.

"magnitudes":
"rakes":
"domain":

{ "2016p858094": 6.0898276 },
{ "2016p858094": 171 },
{ "depth": 39, "duration": 153.58,
"domain": [ {"latitude": -43.151, "longitude": 169.369}, ... ] },
"velocity_model": { "version": "2.07", "min_vs": 0.5, "vs30": 500.0,
"topo_type": "SQUASHED_TAPERED", ... },

… and its own log, 17 entries deep
{ "utility":
"realisation-to-srf",
"version":
"0.1.dev1492+ga2eb23d05",
"timestamp": "2026-08-25T07:06:28",
"args":
["/realisation/R1/realisation.json",
"--genslip-path", "/EMOD3D/tools/genslip_v5.6.2"] }

10 / 12

A question you would not have asked

ims.duckdb one file, 18 GB

293

105 k

111

1.6 B

ruptures

stations

periods

spectral values

Basin sites against rock sites at the
same rupture distance, over every
rupture in the pilot.

11 / 12

Ask for the data transfer too

Clusters we run on

managed data transfer?

TACC

Texas

yes

REANNZ HPC3

New Zealand

yes

ESNZ Cascade

New Zealand

no

MareNostrum 5

Barcelona

no

KISTI

Korea

no

Exascale compute with gigascale data transfer is gigascale compute.

12 / 12

