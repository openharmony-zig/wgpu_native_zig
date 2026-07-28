const audit = @import("binding-audit");

test "wrapper covers every implemented wgpu-native v29 function" {
    comptime {
        @setEvalBranchQuota(10_000_000);
        audit.validate();
    }
}
