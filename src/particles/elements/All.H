/* Copyright 2022 The Regents of the University of California, through Lawrence
 *           Berkeley National Laboratory (subject to receipt of any required
 *           approvals from the U.S. Dept. of Energy). All rights reserved.
 *
 * This file is part of ImpactX.
 *
 * Authors: Axel Huebl
 * License: BSD-3-Clause-LBNL
 */
#ifndef IMPACTX_ELEMENTS_ALL_H
#define IMPACTX_ELEMENTS_ALL_H

#include "Drift.H"
#include "Sbend.H"
#include "Quad.H"
#include "DipEdge.H"
#include "ConstF.H"
#include "ShortRF.H"
#include "Multipole.H"
#include "None.H"
#include "NonlinearLens.H"

#include <variant>


namespace impactx
{
    using KnownElements = std::variant<
        None, /* must be first, so KnownElements creates a default constructor */
        ConstF, DipEdge, Drift, Multipole, NonlinearLens,
        Quad, Sbend, ShortRF>;

} // namespace impactx

#endif // IMPACTX_ELEMENTS_ALL_H
