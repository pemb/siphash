# SipHash: a fast short-input PRF

I've written a VHDL implementation of the SipHash pseudorandom function, as
described in the original paper by Jean-Philippe Aumasson and Daniel
J. Bernstein.

The implementation is validated against the test values provided in the paper
and the C reference implementation.

This implementation provides SipHash-c-2c, with the default of SipHash-2-4.

## Description

From the [official website](https://131002.net/siphash/):

--------------------------------------------------------------------------------

SipHash is a family of pseudorandom functions (a.k.a. keyed hash functions)
optimized for speed on short messages.

Target applications include network traffic authentication and defense against
hash-flooding DoS attacks.

SipHash is secure, fast, and simple (for real):

* SipHash is simpler and faster than previous cryptographic algorithms (e.g.
  MACs based on universal hashing)
* SipHash is competitive in performance with insecure non-cryptographic
  algorithms (e.g. MurmurHash)

We propose that hash tables switch to SipHash as a hash function. Users of
SipHash already include FreeBSD, OpenDNS, Perl 5, Ruby, or Rust. 

--------------------------------------------------------------------------------

## Usage

Operation is rising edge-triggered, with the exception of the asynchronous
reset.

#### Clock signal:

The input `clk` must be driven by a constant clock signal.

#### Asynchronous reset:

During normal operation, the `reset_n` input must be driven high. In the event
that `reset_n` is driven low, all internal registers will be reset, the existing
key value will be erased, and the `hash` output will reset to an undefined
value.

#### Key Loading:

With the `load_k` input asserted, provide the k_0 and k_1 values in the `m`
input, sequentially.

This key value remains stored and will be used by all subsequent hash
calculations, until new values are loaded, or an asynchronous reset is
triggered.

It should be noted that a new key value may be loaded in the interval after the
last block of a hash calculation is processed and the next calculation
begins. This allows for consecutive calculation of hashes with different keys
with no performance penalty, if so desired.

#### Hashing:

##### Initialization:

It is possible to begin calculating a new hash when the output `init_ready` is
asserted. To begin hashing, assert the `init` input when providing the first
block. If the `init` input is asserted when `init_ready` is low, the previous
hash calculation is aborted and a new calculation begins.

##### Input:

At every clock provide a block of up to 64 bits to be hashed in the input
`m`. Byte order is little-endian. `b` must be set to the number of valid bytes
present in the input block, until the last block. Unused bytes must be driven 0.

End of input is signaled by `b` with a value less than 8, indicating the last
block of input. If the last input block is 64 bits in size, this must be treated
as if a 0 bit block followed, so that after the last valid input block, `b` and
`m` must be driven 0 for another clock cycle.

##### Output:

Wait until the `hash_ready` output is asserted, then the result may be read at
the `hash` ouptut. This value will remain until a new hash calculation is
finished, or an asynchronous reset is triggered. The `hash_ready` output will
remain asserted until one cycle after a new hash calculation is initiated.

It should be noted that consecutive hash calculations may overlap by one clock
cycle, because the `init_ready` signal is asserted before `hash_ready`.  If this
happens, the `hash_ready` output will be asserted for a single clock cycle, as
soon as the previous hash calculation is complete.

## Test bench

The included `Makefile` requires ghdl. Run make to compile (please don't use -j,
ghdl gets confused):

    make

To run the test bench, run

    make run

which should print `test vector ok` if everything goes right. If any hashes
fail, assertion error messages should be triggered.

## Implementation and performance considerations

This design is intended to be a good compromise between a minimalistic version,
with only a half-SipRound present in hardware, and a fully unrolled version with
max(c,d) SipRounds in series.

The fully unrolled variant was found to not be advantageous in practice, because
the latency of the full d SipRounds used in finalization must be present in the
clock period for every c SipRound compression iteration (assuming d > c).

Performance is bottlenecked by the 2c 64-bit adders present in the critical
path. FPGA architectures are not well suited for implementing adders other than
ripple-carry, so perhaps an ASIC implementation using carry-lookahead adders
will see dramatic performance improvements.

Using a Cyclone II FPGA as target (EP2C20F484C7), the compilation results are as
follows:

* Maximum frequency: 44.65 MHz
* Logic elements: 1.653
* Registers: 523

## Reference

J.-P. Aumasson and D. J. Bernstein,
“[SipHash: a fast short-input PRF](https://131002.net/siphash/siphash.pdf).”
18-Sep-2012.

## License

This design is licensed under the GPLv3 license.

Copyright (c) 2015, Pedro Brito <pedroembrito@gmail.com>
