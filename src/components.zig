const std = @import("std");
const rl = @import("raylib");

const animation = @import("animation.zig");

const ComponentError = @import("state.zig").ComponentError;

pub const Label = struct {
    label: []const u8,
};

pub const Transform = struct {
    p: rl.Vector2 = rl.Vector2.init(0, 0),
    s: f32 = 1,
    r: f32 = 0,
};

pub const Physics = struct {
    v: rl.Vector2 = rl.Vector2.init(0, 0),
    a: rl.Vector2 = rl.Vector2.init(0, 0),
    f: f32 = 0.01,
    cr: rl.Rectangle = rl.Rectangle.init(0, 0, 0, 0),
    isSolid: bool = false,
    isStatic: bool = false,
};

pub const AnimationComponent = struct {
    animationInstance: animation.AnimationInstance,
};

pub const RandomWalk = struct {
    state: State,
    walkDirection: f32,
    nextStateAt: f64,

    var rand = std.Random.DefaultPrng.init(0);

    const baselineDuration = 6;
    const baselineVariation = 2;

    pub const State = enum {
        idle,
        walking,
    };

    pub fn init() RandomWalk {
        return RandomWalk{
            .state = State.idle,
            .walkDirection = 0,
            .nextStateAt = 0,
        };
    }

    pub fn update(self: *RandomWalk, t: f64) ?State {
        if (self.nextStateAt <= t) {
            self.nextStateAt = self.getNextStateAt();
            self.walkDirection = rand.random().float(f32) * std.math.pi * 2;
            self.state = self.getNextState();

            return self.state;
        }

        return null;
    }

    fn getNextState(_: RandomWalk) State {
        const r = rand.random().float(f32);

        if (r < 0.2) {
            return State.idle;
        } else {
            return State.walking;
        }
    }

    fn getNextStateAt(self: RandomWalk) f64 {
        return self.nextStateAt + baselineDuration + rand.random().float(f64) * baselineVariation;
    }
};

pub fn Components(comptime maxEntities: usize) type {
    return struct {
        transform: [maxEntities]?Transform = undefined,
        physics: [maxEntities]?Physics = undefined,
        texture: [maxEntities]?*const rl.Texture2D = undefined,
        animation: [maxEntities]?AnimationComponent = undefined,
        randomWalk: [maxEntities]?RandomWalk = undefined,
        label: [maxEntities]?Label = undefined,

        pub fn get(c: *Components(maxEntities), comptime T: type, entity: usize) ComponentError!*T {
            const maybeComponent = c.getOptional(T, entity);

            if (maybeComponent.*) |*component| return component;

            return ComponentError.InstanceNotFound;
        }

        pub fn getOptional(c: *Components(maxEntities), comptime T: type, entity: usize) *?T {
            return switch (T) {
                Transform => &c.transform[entity],
                Physics => &c.physics[entity],
                *const rl.Texture2D => &c.texture[entity],
                AnimationComponent => &c.animation[entity],
                RandomWalk => &c.randomWalk[entity],
                Label => &c.label[entity],
                else => @compileError("Component type " ++ @typeName(T) ++ " not supported"),
            };
        }
    };
}