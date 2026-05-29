import os, sys

RED = "\033[31m"
GREEN = "\033[32m"
BOLD = '\033[1m'
UNDERLINE='\033[4m'
NC='\033[0m'

isa_test_path = "isa_test"

def run_isa_test(testname):
    clean_testname = testname.removesuffix(".S")
    bin_path = "build/" + clean_testname + ".bin"
    test_result = os.system(f"""./obj_dir/Vtop -e {bin_path} --max-time 10000 >/dev/null""")

    if testname == "base/fail.S":
        # fail.S test is supposed to fail so if it fails its ok
        if test_result != 0:
            test_result = 0
        else:
            # if it doesnt fail then something is wrong
            test_result = -1

    if test_result != 0:
        print(f"{RED}TEST: {testname} FAILED{NC}")
        print(f"EXIT STATUS {test_result}")
        print("")
        os.system(f"""
            mkdir -p fails/{clean_testname}
            mv build/{clean_testname}.dmp fails/{clean_testname}
            mv waveform.vcd fails/{clean_testname}
        """)
        return False

    return True

def print_results(num_test, num_pass, num_fail):
    if(num_fail != 0):
        print(f"{UNDERLINE}RESULTS{NC}")
        print(f"{RED}[{num_fail}/{num_test}] TEST FAILED{NC}")
        print(f"{GREEN}[{num_pass}/{num_test}] TEST PASSED{NC}")
    else:
        print(f"{GREEN}ALL [{num_pass}/{num_test}] TESTS PASSED{NC}")
    print("")

def run_isa_test_folder(folder):
    num_pass = 0
    num_fail = 0
    num_test = 0
    test_path = f"{isa_test_path}/{folder}"
    
    print(f"{BOLD}STARTING {folder} TESTS...{NC}")
    
    for test in os.listdir(test_path):
        num_test += 1
        os.system(f"make -s _isa_test ISA_TEST={folder}/{test}")

        if run_isa_test(f"{folder}/{test}"):
            num_pass += 1
        else:
            num_fail += 1
    
    print_results(num_test, num_pass, num_fail)


if __name__ == "__main__":
    # Parse arguments
    test_groups_list = sys.argv[1].split(" ")
    for test_group in test_groups_list:
        run_isa_test_folder(test_group)


