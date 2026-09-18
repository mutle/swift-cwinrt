import pathlib
import re
import unittest


class PackageManifestTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = (
            pathlib.Path(__file__).resolve().parents[1] / "Package.swift"
        ).read_text(encoding="utf-8")

    def test_does_not_suppress_consumer_startup_files(self):
        self.assertNotIn("-nostartfiles", self.manifest)

    def test_preserves_dynamic_cwinrt_product(self):
        self.assertRegex(
            self.manifest,
            re.compile(
                r'\.library\(\s*name:\s*"CWinRT",\s*type:\s*\.dynamic,'
                r'\s*targets:\s*\["CWinRT"\]\s*\)'
            ),
        )


if __name__ == "__main__":
    unittest.main()
