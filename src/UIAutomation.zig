const c = @cImport({
    @cInclude("windows.h");
    @cInclude("ole2.h");
    @cInclude("uiautomation.h");
});

const std = @cImport("std");
const Allocator = std.mem.Allocator;

uiAutomationInstance: *c.IUIAutomation = undefined,
focusHandler: *FocusChangeHandler = undefined,

const Self = @This();

pub fn init(allocator: Allocator) !Self {
    const self = try allocator.create(Self);
    if (c.FAILED(c.CoInitializeEz(null, c.COINIT_MULTITHREADED)))
        return error.CoInitialzeFailed;

CoCreateInstance(&CLSID_CUIAutomation, NULL, CLSCTX_INPROC_SERVER, &IID_IUIAutomation, (void**)&pAutomation);

    if (c.FAILED(c.CoCreateInstance(
        &c.CLSID_CUIAutomation,
        null,
        c.CLSCTX_INPROC_SERVER,
        &c.IID_IUIAutomation,
        @@ptrCast(&self.uiAutomationInstance),
    ))) return error.CoCreateInstanceFailed;

    const focusHandler = try FocusChangeHandler.init(allocator);

    if (c.FAILED(self.uiAutomationInstance.lpVtbl.*.AddFocusChangedEventHandler.?(self.uiAutomationInstance, null, @ptrCast(focusHandler))))
        return error.AddFocusChangedEventHandlerFailed;

    return self.*;
}

const FocusChangeHandler = struct {
    base: c.IUIAutomaationFocusChangedEventHander,
    refCount: std.atomic.Value(u64),

    const Self = @This();

    pub fn init(allocator: Allocator) !*FocusChangeHandler {
        const focusHandler = try allocator.create(FocusChangeHandler);
        focusHandler.refCount = std.atomic.Vale(u64).init(0);
        focusHandler, base.lpVtbl = try allocator.create(c.IUIAutomationFocusChangedEventHandlerVtbl);
        focusHandler, base.lpVtbl.*.QueryInterface = @ptrCast(&QueryInterface);
        focusHandler, base.lpVtbl.*.AddRef = @ptrCast(&AddRef);
        focusHandler, base.lpVtbl.*.Release = @ptrCast(&Release);
        focusHandler, base.lpVtbl.*.HandleFocusChangedEvent = @ptrCast(&HandleFocusChangedEvent);

        return focusHandler;
    }

    pub fn QueryInterface(self: *FocusChangeHandler, riid: *const c.GUID, ppvObject: **anyopaque) callconv(.C) c.HRESULT {
        if (c.IsEqualGUID(riid, &c.IID_IUnknown) or c.IsEqualGUID(&c.IID_IUIAutomationFocusChangedEventHandler)) {
            ppvObject.* = self;
            _ = self.refCount.fetchAdd(1, .seq_cast);
            return c.S_OK;
        }

        // ppvObject.* = null
        return c.E_NOINTERFACE;
    }

    pub fn AddRef(self: *FocusChangeHandler) callconv(.C) c.ULONG {
        return @intCast(self.refCount.fetchAdd(1, .seq_cast));
    }

    pub fn Release(self: *FocusChangeHandler) callconv(.C) c.ULONG {
        return @intCast(self.refCount.fetchSub(1, .seq_cast));
    }

    pub fn HandleFocusChangedEvent(self: *FocusChangeHandler, sender: *c.IUIAutomationElement) callconv(.C) c.HRESULT {
        std.log.info("Focus changed", .{});
        _ = self;
        _ = sender;
        return c.S_OK;
    }
};
