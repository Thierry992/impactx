.. _usage-picmi:

Parameters: Python
==================

This documents on how to use ImpactX as a Python script (``python3 run_script.py``).

General
-------

.. py:class:: impactx.ImpactX

   This is the central simulation class.

   .. py:method:: set_particle_shape(order)

      Set the particle B-spline order.

      The order of the shape factors (splines) for the macro-particles along all spatial directions: `1` for linear, `2` for quadratic, `3` for cubic.
      Low-order shape factors result in faster simulations, but may lead to more noisy results.
      High-order shape factors are computationally more expensive, but may increase the overall accuracy of the results.
      For production runs it is generally safer to use high-order shape factors, such as cubic order.

      :param int order: B-spline order ``1``, ``2``, or ``3``


   .. py:method:: set_space_charge(enable)

      Enable or disable space charge calculations (default: enabled).

      Whether to calculate space charge effects.
      This is in-development.
      At the moment, this flag only activates coordinate transformations and charge deposition.

      :param bool enable: enable (true) or disable (false) space charge

   .. py:method:: set_diagnostics(enable)

      Enable or disable diagnostics generally (default: enabled).
      Disabling this is mostly used for benchmarking.

      :param bool enable: enable (true) or disable (false) all diagnostics

   .. py:method:: set_slice_step_diagnostics(enable)

      Enable or disable diagnostics every slice step in elements (default: disabled).

      By default, diagnostics is performed at the beginning and end of the simulation.
      Enabling this flag will write diagnostics every step and slice step.

      :param bool enable: enable (true) or disable (false) all diagnostics

   .. py:method:: set_diag_file_min_digits(file_min_digits)

      The minimum number of digits (default: 6) used for the step
      number appended to the diagnostic file names.

      :param int file_min_digits: number of digits in filenames

   .. py:method:: init_grids()

      Initialize AMReX blocks/grids for domain decomposition & space charge mesh.

      This must come first, before particle beams and lattice elements are initialized.

   .. py:method:: add_particles(charge_C, distr, npart)

      Generate and add n particles to the particle container.
      Note: Set the reference particle properties (charge, mass, energy) first.

      Will also resize the geometry based on the updated particle distribution's extent and then redistribute particles in according AMReX grid boxes.

      :param float charge_C: bunch charge (C)
      :param distr: distribution function to draw from (object from :py:mod:`impactx.distribution`)
      :param int npart: number of particles to draw

   .. py:method:: particle_container()

      Access the beam particle container (:py:class:`impactx.ParticleContainer`).

   .. py:property:: lattice

      Access the elements in the accelerator lattice.
      See :py:mod:`impactx.elements` for lattice elements.

   .. py:method:: evolve()

      Run the main simulation loop for a number of steps.

.. py:class:: impactx.Config

      Configuration information on ImpactX that were set at compile-time.

   .. py:property:: have_mpi

      Indicates multi-process/multi-node support via the `message-passing interface (MPI) <https://www.mpi-forum.org>`__.
      Possible values: ``True``/``False``

      .. note::

         Particle beam particles are not yet dynamically load balanced.
         Please see the progress in `issue 198 <https://github.com/ECP-WarpX/impactx/issues/198>`__.

   .. py:property:: have_gpu

      Indicates GPU support.
      Possible values: ``True``/``False``

   .. py:property:: gpu_backend

      Indicates the available GPU support.
      Possible values: ``None``, ``"CUDA"`` (for Nvidia GPUs), ``"HIP"`` (for AMD GPUs) or ``"SYCL"`` (for Intel GPUs).

   .. py:property:: have_omp

      Indicates multi-threaded CPU support via `OpenMP <https://www.openmp.org>`__.
      Possible values: ``True``/``False```

      Set the environment variable ``OMP_NUM_THREADS`` to control the number of threads.

      .. note::

         Not yet implemented.
         Please see the progress in `issue 195 <https://github.com/ECP-WarpX/impactx/issues/195>`__.

      .. warning::

         By default, OpenMP spawns as many threads as there are available virtual cores on a host.
         When MPI and OpenMP support are used at the same time, it can easily happen that one over-subscribes the available physical CPU cores.
         This will lead to a severe slow-down of the simulation.

         By setting appropriate `environment variables for OpenMP <https://www.openmp.org/spec-html/5.0/openmpch6.html>`__, ensure that the number of MPI processes (ranks) per node multiplied with the number of OpenMP threads is equal to the number of physical (or virtual) CPU cores.
         Please see our examples in the :ref:`high-performance computing (HPC) <install-hpc>` on how to run efficiently in parallel environments such as supercomputers.

Particles
---------

.. py:class:: impactx.ParticleContainer

   Beam Particles in ImpactX.

   This class stores particles, distributed over MPI ranks.

   .. py:method:: add_n_particles(lev, x, y, z, px, py, pyz, qm, bchchg)

      Add new particles to the container

      Note: This can only be used *after* the initialization (grids) have
            been created, meaning after the call to :py:meth:`ImpactX.init_grids`
            has been made in the ImpactX class.

      :param lev: mesh-refinement level
      :param x: positions in x
      :param y: positions in y
      :param z: positions in z
      :param px: momentum in x
      :param py: momentum in y
      :param pz: momentum in z
      :param qm: charge over mass in 1/eV
      :param bchchg: total charge within a bunch in C

   .. py:method:: ref_particle()

      Access the reference particle (:py:class:`impactx.RefPart`).

      :return: return a data reference to the reference particle
      :rtype: impactx.RefPart

   .. py:method:: set_ref_particle(refpart)

      Set reference particle attributes.

      :param impactx.RefPart refpart: a reference particle to copy all attributes from

.. py:class:: impactx.RefPart

   This struct stores the reference particle attributes stored in :py:class:`impactx.ParticleContainer`.

   .. py:property:: s

      integrated orbit path length, in meters

   .. py:property:: x

      horizontal position x, in meters

   .. py:property:: y

      vertical position y, in meters

   .. py:property:: z

      longitudinal position y, in meters

   .. py:property:: t

      clock time * c in meters

   .. py:property:: px

      momentum in x, normalized to proper velocity

   .. py:property:: py

      momentum in y, normalized to proper velocity

   .. py:property:: pz

      momentum in z, normalized to proper velocity

   .. py:property:: pt

      energy deviation, normalized by rest energy

   .. py:property:: gamma

      Read-only: Get reference particle relativistic gamma.

   .. py:property:: beta

      Read-only: Get reference particle relativistic beta.

   .. py:property:: beta_gamma

      Read-only: Get reference particle beta*gamma

   .. py:property:: qm_qeeV

      Read-only: Get reference particle charge to mass ratio (elementary charge/eV)

   .. py:method:: set_charge_qe(charge_qe)

      Write-only: Set reference particle charge in (positive) elementary charges.

   .. py:method:: set_mass_MeV(massE)

      Write-only: Set reference particle rest mass (MeV/c^2).

   .. py:method:: set_energy_MeV(energy_MeV)

      Write-only: Set reference particle energy.

   .. py:method:: load_file(madx_file)

      Load reference particle information from a MAD-X file.

      :param madx_file: file name to MAD-X file with a ``BEAM`` entry


Initial Beam Distributions
--------------------------

This module provides particle beam distributions that can be used to initialize particle beams in an :py:class:`impactx.ParticleContainer`.

.. py:module:: impactx.distribution
   :synopsis: Particle beam distributions in ImpactX

.. py:class:: impactx.distribution.Gaussian(sigx, sigy, sigt, sigpx, sigpy, sigpt, muxpx=0.0, muypy=0.0, mutpt=0.0)

   A 6D Gaussian distribution.

   :param sigx: for zero correlation, these are the related RMS sizes (in meters)
   :param sigy: see sigx
   :param sigt: see sigx
   :param sigpx: RMS momentum
   :param sigpy: see sigpx
   :param sigpt: see sigpx
   :param muxpx: correlation length-momentum
   :param muypy: see muxpx
   :param mutpt: see muxpx

.. py:class:: impactx.distribution.Kurth4D(sigx, sigy, sigt, sigpx, sigpy, sigpt, muxpx=0.0, muypy=0.0, mutpt=0.0)

   A 4D Kurth distribution transversely + a uniform distribution
   it t + a Gaussian distribution in pt.

.. py:class:: impactx.distribution.Kurth6D(sigx, sigy, sigt, sigpx, sigpy, sigpt, muxpx=0.0, muypy=0.0, mutpt=0.0)

   A 6D Kurth distribution.

   R. Kurth, Quarterly of Applied Mathematics vol. 32, pp. 325-329 (1978)
   C. Mitchell, K. Hwang and R. D. Ryne, IPAC2021, WEPAB248 (2021)

.. py:class:: impactx.distribution.KVdist(sigx, sigy, sigt, sigpx, sigpy, sigpt, muxpx=0.0, muypy=0.0, mutpt=0.0)

   A K-V distribution transversely + a uniform distribution
   it t + a Gaussian distribution in pt.

.. py:class:: impactx.distribution.None

   This distribution does nothing.

.. py:class:: impactx.distribution.Semigaussian(sigx, sigy, sigt, sigpx, sigpy, sigpt, muxpx=0.0, muypy=0.0, mutpt=0.0)

   A 6D Semi-Gaussian distribution (uniform in position, Gaussian in momentum).

.. py:class:: impactx.distribution.Waterbag(sigx, sigy, sigt, sigpx, sigpy, sigpt, muxpx=0.0, muypy=0.0, mutpt=0.0)

   A 6D Waterbag distribution.


Lattice Elements
----------------

This module provides elements for the accelerator lattice.

.. py:module:: impactx.elements
   :synopsis: Accelerator lattice elements in ImpactX

.. py:class:: impactx.elements.KnownElementsList

   An iterable, ``list``-like type of elements.

   .. py:method:: clear()

      Clear the list to become empty.

   .. py:method:: extend(list)

      Add a list of elements to the list.

   .. py:method:: append(element)

      Add a single element to the list.

   .. py:method:: load_file(madx_file, nslice=1)

      Load and append an accelerator lattice description from a MAD-X file.

      :param madx_file: file name to MAD-X file with beamline elements
      :param nslice: number of slices used for the application of space charge

.. py:class:: impactx.elements.ConstF(ds, kx, ky, kt, nslice=1)

   A linear Constant Focusing element.

   :param ds: Segment length in m.
   :param kx: Focusing strength for x in 1/m.
   :param ky: Focusing strength for y in 1/m.
   :param kt: Focusing strength for t in 1/m.
   :param nslice: number of slices used for the application of space charge

.. py:class:: impactx.elements.DipEdge(psi, rc, g, K2)

   Edge focusing associated with bend entry or exit

   This model assumes a first-order effect of nonzero gap.
   Here we use the linear fringe field map, given to first order in g/rc (gap / radius of curvature).

   References:
   * K. L. Brown, SLAC Report No. 75 (1982).
   * K. Hwang and S. Y. Lee, PRAB 18, 122401 (2015).

   :param psi: Pole face angle in rad
   :param rc: Radius of curvature in m
   :param g: Gap parameter in m
   :param K2: Fringe field integral (unitless)

.. py:class:: impactx.elements.Drift(ds, nslice=1)

   A drift.

   :param ds: Segment length in m
   :param nslice: number of slices used for the application of space charge

.. py:class:: impactx.elements.Multipole(multipole, K_normal, K_skew)

   A general thin multipole element.

   :param multipole: index m (m=1 dipole, m=2 quadrupole, m=3 sextupole etc.)
   :param K_normal: Integrated normal multipole coefficient (1/meter^m)
   :param K_skew: Integrated skew multipole coefficient (1/meter^m)

.. py::class:: impactx.elements.None

   This element does nothing.

.. py:class:: impactx.elements.NonlinearLens(knll, cnll)

   Single short segment of the nonlinear magnetic insert element

   A thin lens associated with a single short segment of the
   nonlinear magnetic insert described by V. Danilov and
   S. Nagaitsev, PRSTAB 13, 084002 (2010), Sect. V.A.  This
   element appears in MAD-X as type NLLENS.

   :param knll: integrated strength of the nonlinear lens (m)
   :param cnll: distance of singularities from the origin (m)

.. py:class:: impactx.elements.Quad(ds, k, nslice=1)

   A Quadrupole magnet.

   :param ds: Segment length in m.
   :param k:  Quadrupole strength in m^(-2) (MADX convention)
              = (gradient in T/m) / (rigidity in T-m)
              k > 0 horizontal focusing
              k < 0 horizontal defocusing
   :param nslice: number of slices used for the application of space charge

.. py:class:: impactx.elements.Sbend(ds, rc, nslice=1)

   An ideal sector bend.

   :param ds: Segment length in m.
   :param rc: Radius of curvature in m.
   :param nslice: number of slices used for the application of space charge

.. py:class:: impactx.elements.ShortRF(V, k)

   A short RF cavity element at zero crossing for bunching.

   :param V: Normalized RF voltage drop V = Emax*L/(c*Brho)
   :param k: Wavenumber of RF in 1/m
