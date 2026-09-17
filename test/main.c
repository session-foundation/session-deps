// Deliberately trivial: this program exists to be linked, not run.  Building it proves the
// dependency targets and the link flags they carry are coherent; the recipes themselves having
// built is what the CI job is really checking.
int main(void) {
    return 0;
}
