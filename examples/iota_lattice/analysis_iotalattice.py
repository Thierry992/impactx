#!/usr/bin/env python3
#
# Copyright 2022 ImpactX contributors
# Authors: Axel Huebl, Chad Mitchell
# License: BSD-3-Clause-LBNL
#

import glob

import numpy as np
import pandas as pd
from scipy.stats import moment


def get_moments(beam):
    """Calculate standard deviations of beam position & momenta
    and emittance values

    Returns
    -------
    sigx, sigy, sigt, emittance_x, emittance_y, emittance_t
    """
    sigx = moment(beam["x"], moment=2) ** 0.5  # variance -> std dev.
    sigpx = moment(beam["px"], moment=2) ** 0.5
    sigy = moment(beam["y"], moment=2) ** 0.5
    sigpy = moment(beam["py"], moment=2) ** 0.5
    sigt = moment(beam["t"], moment=2) ** 0.5
    sigpt = moment(beam["pt"], moment=2) ** 0.5

    epstrms = beam.cov(ddof=0)
    emittance_x = (sigx**2 * sigpx**2 - epstrms["x"]["px"] ** 2) ** 0.5
    emittance_y = (sigy**2 * sigpy**2 - epstrms["y"]["py"] ** 2) ** 0.5
    emittance_t = (sigt**2 * sigpt**2 - epstrms["t"]["pt"] ** 2) ** 0.5

    return (sigx, sigy, sigt, emittance_x, emittance_y, emittance_t)


def read_all_files(file_pattern):
    """Read in all CSV files from each MPI rank (and potentially OpenMP
    thread). Concatenate into one Pandas dataframe.

    Returns
    -------
    pandas.DataFrame
    """
    return pd.concat(
        (
            pd.read_csv(filename, delimiter=r"\s+")
            for filename in glob.glob(file_pattern)
        ),
        axis=0,
        ignore_index=True,
    ).set_index("id")


# initial/final beam on rank zero
initial = read_all_files("diags/beam_000000.*")
final = read_all_files("diags/beam_final.*")

# compare number of particles
num_particles = 10000
assert num_particles == len(initial)
assert num_particles == len(final)

print("Initial Beam:")
sigx, sigy, sigt, emittance_x, emittance_y, emittance_t = get_moments(initial)
print(f"  sigx={sigx:e} sigy={sigy:e} sigt={sigt:e}")
print(
    f"  emittance_x={emittance_x:e} emittance_y={emittance_y:e} emittance_t={emittance_t:e}"
)

atol = 1.0  # a big number
rtol = num_particles**-0.5  # from random sampling of a smooth distribution
print(f"  rtol={rtol} (ignored: atol~={atol})")

assert np.allclose(
    [sigx, sigy, sigt, emittance_x, emittance_y, emittance_t],
    [1.595934e-03, 2.507263e-03, 9.977588e-04, 4.490896e-06, 4.539378e-06, 0.000000e00],
    rtol=rtol,
    atol=atol,
)


print("")
print("Final Beam:")
sigx, sigy, sigt, emittance_x, emittance_y, emittance_t = get_moments(final)
print(f"  sigx={sigx:e} sigy={sigy:e} sigt={sigt:e}")
print(
    f"  emittance_x={emittance_x:e} emittance_y={emittance_y:e} emittance_t={emittance_t:e}"
)

atol = 1.0  # a big number
rtol = num_particles**-0.5  # from random sampling of a smooth distribution
print(f"  rtol={rtol} (ignored: atol~={atol})")

assert np.allclose(
    [sigx, sigy, sigt, emittance_x, emittance_y, emittance_t],
    [
        1.579848e-03,
        2.510900e-03,
        1.208202e-02,
        4.490897e-06,
        4.539378e-06,
        6.384184e-16,
    ],
    rtol=rtol,
    atol=atol,
)
