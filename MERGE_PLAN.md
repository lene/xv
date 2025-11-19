# Merge Plan: xv-gitlab → xv-github

**Date**: 2025-11-19
**Purpose**: Merge packaging and distribution features from xv-gitlab into xv-github (master copy)
**Strategy**: Two-phase approach - first merge optimizations to main, then merge packaging features

---

## Phase 1: Merge Current Optimization Work to Main

### Goal
Get all window optimization work from current branch onto main branch.

### Steps
1. Checkout main branch
2. Merge current branch (`claude/optimize-resource-allocation-011FMM7jp5YpDLc4yUPCom2Y`) to main
3. Push to origin/main

### Commits Being Merged
- Fix missing guard in selectCell() and disable Sanitizers module
- Enable gamma window lazy creation (Phase 2A complete)
- Add comprehensive automated test suite for lazy window creation optimizations
- Test implementations and validation scripts
- Phase 1 test results and documentation
- (19 commits total)

---

## Phase 2: Merge xv-gitlab Features

### Goal
Add Debian packaging, PPA distribution, and -nolimits WM compatibility to the optimized codebase.

---

## What Will Be Merged

### 1. -nolimits Window Manager Fix ⭐⭐⭐
**Source**: xv-gitlab/xv-6.0.4-src commit c1aea1d
**Files**: src/xv.c, src/xvevent.c, src/xvimage.c
**Lines**: ~120 lines of changes

**Purpose**: Enables viewing high-resolution images larger than screen size on modern restrictive window managers (Gnome/Mutter)

**Technical Details**:
- Uses PMinSize WM hints to force full-size window creation
- Dynamically updates PMinSize when user resizes via keyboard
- Skips maxWIDE/maxHIGH constraints with -nolimits active
- Allows ConfigureNotify-based resizing
- Skips screen position clamping and aspect ratio fixes

**Merge Complexity**: MEDIUM - May conflict with lazy window creation optimizations
**Testing Required**: Verify -nolimits works with optimized window creation

---

### 2. Debian Packaging Infrastructure ⭐⭐⭐
**Source**: xv-gitlab/xv-6.0.4-src/debian/
**Action**: Copy entire directory

**Files to Copy**:
- debian/control - Package metadata, dependencies for Ubuntu 24.04
- debian/rules - CMake-based build rules
- debian/changelog - Version history (will update for optimized version)
- debian/compat - debhelper compatibility level (13)
- debian/docs - Documentation files to include
- debian/copyright - **NEEDS FIX**: Currently references Nicotine+
- debian/cleanup - Post-build cleanup script
- debian/source/format - Source format (3.0 quilt)
- debian/source/options - Build options
- debian/watch - **NEEDS FIX**: Currently monitors Nicotine+ GitHub
- debian/tests/control - **NEEDS FIX**: References Nicotine+ tests
- debian/tests/test-installed-artifacts.sh - **NEEDS FIX**: Nicotine+ test script
- debian/files - Generated file list

**Fixes Required**:
All files marked **NEEDS FIX** contain copy-paste errors from a Nicotine+ package template and must be corrected to reference XV instead.

**Specific Corrections Needed**:
1. debian/copyright - Replace Nicotine+ license/copyright with XV
2. debian/watch - Point to jasper-software/xv GitHub releases
3. debian/tests/control - Update test dependencies for XV
4. debian/tests/test-installed-artifacts.sh - Create XV-specific tests (e.g., `xv --version`)

**Update Required**:
- debian/changelog - Add entry for optimized xv-github version

---

### 3. PPA Publishing Workflow ⭐⭐
**Source**: xv-gitlab/xv-6.0.4-src/.github/workflows/publish-to-ppa.yml
**Action**: Copy to .github/workflows/
**Lines**: 148 lines

**Features**:
- Automated PPA upload on version tags
- Manual workflow dispatch with version/distribution selection
- GPG signing integration (secrets-based)
- Supports noble/jammy/mantic distributions
- Creates source packages for Launchpad build system

**Current Status**: Blocked by Launchpad GPG key registration issue (see LAUNCHPAD_KEY_ISSUE.md)

**Secrets Required** (for GitHub Actions):
- GPG_PRIVATE_KEY
- GPG_PASSPHRASE
- LAUNCHPAD_PPA (format: ppa:username/ppa-name)

---

### 4. Documentation ⭐
**Files to Copy**:

1. **EVALUATION.md** (197 lines)
   - Comprehensive comparison of old xv-3.10a vs jasper-software/xv
   - Build results and dependency analysis
   - Historical context for the migration

2. **MIGRATION_SUMMARY.md** (163 lines)
   - Step-by-step migration documentation
   - Source upgrade details (xv-3.10a → v6.0.4)
   - Build system modernization explanation
   - Success metrics

3. **LAUNCHPAD_KEY_ISSUE.md** (127 lines from xv-gitlab/xv-6.0.4-src/)
   - Documents PPA blocker: GPG key stuck in Launchpad registration
   - Troubleshooting steps attempted
   - Contact information for Launchpad support
   - Workaround suggestions

4. **GITHUB_ISSUE_TEMPLATE.md** (85 lines from xv-gitlab/xv-6.0.4-src/)
   - Template for creating GitHub issue about Launchpad key problem

---

### 5. CLAUDE.md Merge Strategy ⭐⭐
**Action**: Merge both versions manually

**Current Content**:
- **xv-github CLAUDE.md**: Focuses on X window optimizations, lazy creation patterns, testing infrastructure
- **xv-gitlab CLAUDE.md**: Focuses on Debian packaging, PPA distribution, Ubuntu 24.04 targeting

**Merge Strategy**:
Combine both into comprehensive development guide with sections:
1. Project Overview (from xv-github)
2. Build System (from xv-github)
3. Testing (from xv-github - comprehensive test suite)
4. Architecture (from xv-github - optimization patterns)
5. **ADD: Debian Packaging** (from xv-gitlab)
6. **ADD: PPA Distribution** (from xv-gitlab)
7. Code Style and Conventions (from xv-github)
8. Key Implementation Details (from xv-github)
9. Important Investigation Documents (from xv-github)
10. Common Development Workflows (merged from both)
11. **ADD: Package Building Workflow** (from xv-gitlab)
12. Known Issues and Limitations (merged from both)
13. Resources (merged)
14. Git Workflow (merged)

---

### 6. .gitignore Updates
**Action**: Add Debian build artifacts

**Add to .gitignore**:
```
# Debian packaging artifacts
debian/.debhelper/
debian/xv/
debian/files
debian/*.substvars
debian/*.log
*.deb
*.ddeb
*.dsc
*.build
*.buildinfo
*.changes
*.tar.xz
*.tar.gz
debian/debhelper-build-stamp
```

---

## What Will NOT Be Merged

### Legacy Files (Not Useful)
- `create_deb.sh` - Obsolete script for old xv-3.10a build
- `Dockerfile` - Legacy Ubuntu 20.04 build environment
- `Dockerfile_deb` - Old static linking build environment
- `.gitlab-ci.yml` - GitLab-specific CI (we use GitHub Actions)

### Old Source Tarballs (Historical, Not Needed)
- `zlib-1.2.11.tar.gz` (607 KB)
- `libpng-1.2.54.tar.bz2` (720 KB)
- `xv-3.10a.tar.gz` (2.3 MB)
- `xv-3.10a-jumbo-patches-20050501.tar.gz` (449 KB)
- `xv-3.10a-jumbo20050501-1.diff.gz` (484 KB)

### Build Artifacts (Should Never Be in Version Control)
- All `xv_*.deb`, `xv_*.buildinfo`, `xv_*.changes` files
- `xv.o`, `xv.gif` - Compiled object files
- `xv_*.orig.tar.gz` - Source tarballs

### Personal Files
- `my-gpg-public-key.asc` - Personal GPG key
- `launchpad-message.txt` - Encrypted personal PGP message

### xv-6.0.4-src Subdirectory
The entire `xv-6.0.4-src/` subdirectory structure from xv-gitlab is not needed because xv-github already has the source in the root `src/` directory. We only need specific files from within this subdirectory.

---

## Implementation Steps

### Phase 1: Merge Optimizations to Main

```bash
# Step 1: Checkout main
git checkout main

# Step 2: Merge optimization branch
git merge claude/optimize-resource-allocation-011FMM7jp5YpDLc4yUPCom2Y

# Step 3: Push to origin
git push origin main
```

---

### Phase 2: Create Feature Branch and Merge xv-gitlab Features

```bash
# Step 1: Create feature branch from main
git checkout -b merge-packaging-features main

# Step 2: Add xv-gitlab source as remote
git remote add xv-gitlab-src /home/lene/workspace/xv-gitlab/xv-6.0.4-src
git fetch xv-gitlab-src

# Step 3: Cherry-pick -nolimits fix
git cherry-pick c1aea1d8d97926da732cf0aeda8b64445ffd1191
# Resolve conflicts carefully - this is the most complex step
# Priority: Keep optimization code, integrate -nolimits logic

# Step 4: Copy Debian packaging directory
cp -r /home/lene/workspace/xv-gitlab/xv-6.0.4-src/debian .

# Step 5: Fix Nicotine+ references in debian files
# Edit debian/copyright - replace Nicotine+ with XV info
# Edit debian/watch - point to jasper-software/xv
# Edit debian/tests/control - replace nicotine references
# Edit debian/tests/test-installed-artifacts.sh - create XV tests

# Step 6: Update debian/changelog
# Add new entry for optimized version (e.g., 6.0.4-2~noble)

# Step 7: Copy PPA publishing workflow
cp /home/lene/workspace/xv-gitlab/xv-6.0.4-src/.github/workflows/publish-to-ppa.yml \
   .github/workflows/

# Step 8: Copy documentation files
cp /home/lene/workspace/xv-gitlab/EVALUATION.md .
cp /home/lene/workspace/xv-gitlab/MIGRATION_SUMMARY.md .
cp /home/lene/workspace/xv-gitlab/xv-6.0.4-src/LAUNCHPAD_KEY_ISSUE.md .
cp /home/lene/workspace/xv-gitlab/xv-6.0.4-src/GITHUB_ISSUE_TEMPLATE.md .

# Step 9: Merge CLAUDE.md
# Manually combine both versions - keep optimization docs, add packaging sections

# Step 10: Update .gitignore
# Add Debian build artifact patterns

# Step 11: Commit all changes
git add debian/ .github/workflows/publish-to-ppa.yml
git add EVALUATION.md MIGRATION_SUMMARY.md LAUNCHPAD_KEY_ISSUE.md GITHUB_ISSUE_TEMPLATE.md
git add CLAUDE.md .gitignore
git commit -m "Merge packaging and PPA distribution features from xv-gitlab

- Add -nolimits window manager compatibility fix
- Add complete Debian packaging infrastructure (debian/)
- Add PPA publishing GitHub Actions workflow
- Add migration and evaluation documentation
- Update CLAUDE.md with packaging workflows
- Fix Nicotine+ references in debian files
- Update .gitignore for Debian build artifacts

This combines the X window optimization work with professional
Ubuntu/Debian packaging and distribution capabilities."

# Step 12: Push feature branch
git push -u origin merge-packaging-features
```

---

## Testing Checklist

### After Phase 1 (Main Branch Merge)
- [ ] Build succeeds: `cmake -H. -Btmp_cmake && cmake --build tmp_cmake`
- [ ] All tests pass: `./tests/run_tests.sh`
- [ ] Window count is optimized (minimal X windows created)

### After Phase 2 (Packaging Features Merge)

#### Build Testing
- [ ] CMake build succeeds: `cmake -H. -Btmp_cmake && cmake --build tmp_cmake`
- [ ] Binary runs: `./tmp_cmake/src/xv --version`

#### Optimization Testing
- [ ] All existing tests pass: `./tests/run_tests.sh`
- [ ] Static analysis passes: `./tests/test_static_analysis.sh`
- [ ] Window count test passes: `xvfb-run -a ./tests/test_window_count.sh`
- [ ] Functional tests pass: `xvfb-run -a ./tests/test_functionality.sh`

#### -nolimits Testing
- [ ] -nolimits flag accepted: `./tmp_cmake/src/xv -nolimits large_image.jpg`
- [ ] Can view image larger than screen
- [ ] Window resizes properly with -nolimits
- [ ] Works with optimized window creation

#### Debian Package Testing
- [ ] Package builds: `dpkg-buildpackage -us -uc -b`
- [ ] Package installs: `sudo dpkg -i ../xv_*.deb`
- [ ] Installed binary works: `xv --version`
- [ ] All dependencies satisfied: `ldd /usr/bin/xv`
- [ ] Can view images: `xv /path/to/test.jpg`
- [ ] Optimizations active in installed package

#### Documentation Testing
- [ ] CLAUDE.md is comprehensive and accurate
- [ ] All referenced files exist
- [ ] Build instructions work
- [ ] Packaging instructions work

---

## Expected Conflicts and Resolutions

### 1. Source Code Conflicts (Cherry-pick c1aea1d)

**Files with Likely Conflicts**:
- `src/xv.c` - Both modified for -nolimits and optimizations
- `src/xvevent.c` - Both modified event handling
- `src/xvimage.c` - Both modified image display

**Resolution Strategy**:
1. Accept incoming -nolimits changes for WM hint logic
2. Keep existing optimization changes for lazy window creation
3. Ensure both features work together:
   - -nolimits affects window size constraints
   - Optimizations affect window creation timing
   - No logical conflict, just need both code paths

**Testing After Conflict Resolution**:
- Build and run all tests
- Specifically test -nolimits with large images
- Verify window count remains optimized

### 2. CLAUDE.md Conflict

**Issue**: Completely different content in both files

**Resolution**: Manual merge, not automatic
- Keep all optimization/testing documentation from xv-github
- Add packaging/PPA sections from xv-gitlab
- Reorganize for logical flow
- Update table of contents

### 3. .gitignore Additions

**Issue**: Different ignored patterns

**Resolution**: Combine both
- Keep existing patterns from xv-github
- Add Debian artifact patterns
- Sort alphabetically within sections

---

## Success Criteria

After successful merge, xv-github will have:

### Technical Features
- ✅ X window lazy creation optimizations (~140 → minimal windows)
- ✅ Comprehensive test suite (14 test scripts)
- ✅ -nolimits window manager compatibility
- ✅ All optimizations verified working

### Distribution Features
- ✅ Complete Debian packaging infrastructure
- ✅ Ubuntu 24.04 (Noble) support
- ✅ PPA publishing automation (GitHub Actions)
- ✅ Professional package metadata

### Documentation
- ✅ Combined optimization + packaging documentation
- ✅ Migration history preserved
- ✅ PPA blocker documented
- ✅ Development workflows for both features

### Quality Assurance
- ✅ All tests passing
- ✅ Clean build with no warnings
- ✅ Debian package builds successfully
- ✅ Installed package works correctly

---

## Post-Merge Actions

### Short-term (After Merge Complete)
1. Test package installation on clean Ubuntu 24.04 system
2. Verify all documentation is accurate
3. Create GitHub release with optimized version
4. Update README.md with installation instructions

### Medium-term (Next Steps)
1. Resolve Launchpad GPG key issue (contact support per LAUNCHPAD_KEY_ISSUE.md)
2. Upload optimized package to PPA
3. Test PPA installation on multiple Ubuntu versions
4. Consider merging feature branch to main

### Long-term (Maintenance)
1. Monitor for issues with -nolimits on different window managers
2. Keep Debian packaging updated for new Ubuntu releases
3. Continue optimization work (Phase 2B, Phase 3)
4. Contribute -nolimits fix back to jasper-software/xv upstream

---

## Rollback Plan

If merge causes issues:

```bash
# If still on feature branch and haven't merged to main
git checkout main
git branch -D merge-packaging-features

# If merged to main and need to revert
git checkout main
git revert <merge-commit-sha>
git push origin main

# If need to completely reset main
git checkout main
git reset --hard origin/main
```

---

## Notes and Warnings

### About the -nolimits Fix
- This is a user-facing feature for professional use cases
- Critical for photographers/designers viewing high-res images
- Complements optimizations perfectly (fast startup + full image viewing)

### About Debian Packaging
- All Nicotine+ references MUST be fixed before first package release
- Test package on clean system before PPA upload
- debian/changelog format is strict - follow existing pattern

### About PPA Publishing
- Currently blocked by Launchpad GPG key registration
- Workflow is ready but cannot publish until key issue resolved
- See LAUNCHPAD_KEY_ISSUE.md for resolution path

### About Code Quality
- Both optimization and -nolimits changes are well-documented
- Extensive testing infrastructure exists
- Professional-grade packaging setup

---

## References

### Git Repositories
- **xv-github**: git@github.com:lene/xv.git (master copy)
- **xv-gitlab**: git@gitlab.com:lilacashes/xv.git (packaging source)
- **Upstream**: https://github.com/jasper-software/xv (jasper-software)

### Key Commits
- **c1aea1d**: -nolimits WM fix (xv-gitlab/xv-6.0.4-src)
- **003fc30**: Debian packaging addition (xv-gitlab/xv-6.0.4-src)
- **62f9fb1**: Latest optimization work (xv-github current branch)

### Documentation
- This plan: MERGE_PLAN.md
- Analysis: See agent research output above
- Testing: tests/README.md (xv-github)
- Packaging: EVALUATION.md, MIGRATION_SUMMARY.md (from xv-gitlab)

---

**Plan Status**: Ready for execution
**Estimated Time**: 2-3 hours including testing
**Risk Level**: Medium (due to source code conflicts)
**Confidence**: High (both features are well-understood)
