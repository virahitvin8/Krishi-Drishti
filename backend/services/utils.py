"""
Krishi Drishti - Shared Utility Functions

Common helpers used across services (hashing, coordinate math, etc.).
"""
import zlib


def stable_hash(value: str) -> int:
    """Create a deterministic hash that does not change across Python runs.

    Uses Adler-32 (fast, deterministic, cross-platform).
    """
    return zlib.adler32(value.encode("utf-8")) & 0x7FFFFFFF
