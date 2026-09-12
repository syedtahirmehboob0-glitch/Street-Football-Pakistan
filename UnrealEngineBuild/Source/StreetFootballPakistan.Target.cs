using UnrealBuildTool;
using System.Collections.Generic;

public class StreetFootballPakistanTarget : TargetRules
{
    public StreetFootballPakistanTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Game;
        DefaultBuildSettings = BuildSettingsVersion.V6;
        IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_8;
        ExtraModuleNames.Add("StreetFootballPakistan");
    }
}
