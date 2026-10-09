/*
 * Restores android::base::Trim(std::string const&) for the stock NXP NFC blobs.
 *
 * nfc_nci_nxpsn.so and ese_spi_nxp.so are prebuilts that reference the
 * non-template overload Android 14 removed from libbase, so the dynamic linker
 * cannot resolve it and the HALs die before they start:
 *
 *   CANNOT LINK EXECUTABLE "/vendor/bin/hw/nxp.android.hardware.nfc@1.2-service":
 *     cannot locate symbol "_ZN7android4base4TrimERKNSt3__1...E"
 *     referenced by "/vendor/lib64/nfc_nci_nxpsn.so"
 *
 * The name is spelled out with an asm label rather than written as a C++ signature:
 * mangling depends on the target's standard library ABI, and a name that is even
 * slightly off is silently useless at runtime.
 *
 * The body trims ASCII whitespace from both ends, as the removed implementation
 * did.  It is a strong definition, so it wins over the weak template
 * instantiations libbase provides.
 */

#include <string>

// std::string android::base::Trim(std::string const&)
std::string trim_for_legacy_nfc(const std::string& s)
    __asm__("_ZN7android4base4TrimERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE");

std::string trim_for_legacy_nfc(const std::string& s) {
    static const char kWhitespace[] = " \t\n\v\f\r";

    const std::string::size_type begin = s.find_first_not_of(kWhitespace);
    if (begin == std::string::npos) {
        return std::string();
    }
    const std::string::size_type end = s.find_last_not_of(kWhitespace);
    return s.substr(begin, end - begin + 1);
}
