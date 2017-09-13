;This contains the locations of various memory segments and global variables

;=====================================================================================
; BIOS CONSTANTS
;=====================================================================================

BIOS.DAP.Size						equ 0x10

;=====================================================================================
; ISO CONSTANTS
;=====================================================================================

;Directory
ISO.DIR.Length						equ 00
ISO.DIR.ExtendedAttributeLength		equ 01
ISO.DIR.LocationLBA					equ 02
ISO.DIR.DataLength					equ 10
ISO.DIR.RecordingDateTime			equ 18
ISO.DIR.FileFlags					equ 25
ISO.DIR.FileUnitSize				equ 26
ISO.DIR.InterleaveGapSize			equ 27
ISO.DIR.VolumeSequenceNumber		equ 28
ISO.DIR.LengthOfFileIdentifier		equ 32
ISO.DIR.FileIdentifier				equ 33

;Primary Volume Descriptor
ISO.PVD.TypeCode					equ 0000
ISO.PVD.StandardID					equ 0001
ISO.PVD.Version						equ 0006
ISO.PVD.Unused1						equ 0007
ISO.PVD.SystemIdentifier			equ 0008
ISO.PVD.VolumeIdentifier			equ 0040
ISO.PVD.Unused2						equ 0072
ISO.PVD.VolumeSpaceSize				equ 0080
ISO.PVD.Unused3						equ 0088
ISO.PVD.VolumeSetSize				equ 0120
ISO.PVD.VolumeSequenceNumber		equ 0124
ISO.PVD.LogicalBlockSize			equ 0128
ISO.PVD.PathTableSize				equ 0132
ISO.PVD.LocationOfLPathTable		equ	0140
ISO.PVD.LocationOfOLPathTable		equ 0144
ISO.PVD.LocationOfMPathTable		equ 0148
ISO.PVD.LocationOfOMPathTable		equ 0152
ISO.PVD.RootDirEntry				equ 0156
ISO.PVD.VolumeSetIdentifier			equ 0190
ISO.PVD.PublisherIdentifier			equ 0318
ISO.PVD.DataPreparerIdentifier		equ 0446
ISO.PVD.ApplicationIdentifier		equ 0574
ISO.PVD.CopyrightFileIdentifier		equ 0702
ISO.PVD.AbstractFileIdentifier		equ 0740
ISO.PVD.BibliogrpahicFileIdentifier	equ 0776
ISO.PVD.VolumeCreationDateTime		equ 0813
ISO.PVD.VolumeExpirationDateTime	equ 0847
ISO.PVD.VolumeEffectiveDateTime		equ 0864
ISO.PVD.FileStructureVersion		equ 0881
ISO.PVD.Unused4						equ 0882
ISO.PVD.ApplicationUsed				equ 0883
ISO.PVD.Reserved					equ 1395


;=====================================================================================
; MEMORY CONSTANTS
;=====================================================================================

Memory.Loader1						equ 0x7C00
Memory.Loader1.Segment              equ Memory.Loader1 >> 4
Memory.Loader2						equ 0x8000
Memory.Loader2.Segment				equ Memory.Loader2 >> 4
Memory.Sector.Buffer				equ 0x0800
Memory.Sector.Buffer.Size			equ 2048
Memory.Stack.Bottom					equ 0x4000
Memory.Stack.Top					equ	0x7C00
Memory.Video.ModeBuffer				equ 0x0700


;=====================================================================================
; VIDEO CONSTANTS
;=====================================================================================

Video.Mode.Attributes				equ 0x00
Video.Mode.WindowAAttributes		equ 0x02
Video.Mode.WindowBAttributes		equ 0x03
Video.Mode.WindowGranularity		equ 0x04
Video.Mode.WindowSize				equ 0x06
Video.Mode.StartOfWindowA			equ 0x08
Video.Mode.StartOfWindowB			equ 0x0A
Video.Mode.FARWindowPositionFunc	equ 0x0C
Video.Mode.Pitch					equ 0x10
Video.Mode.Width					equ 0x12
Video.Mode.Height					equ 0x14
Video.Mode.CharacterWidth			equ 0x16
Video.Mode.CharacterHeight			equ 0x17
Video.Mode.MemoryPlanes				equ 0x18
Video.Mode.BPP						equ 0x19
Video.Mode.Banks					equ 0x1A
Video.Mode.MemoryModelType			equ 0x1B
Video.Mode.SizeOfBank				equ 0x1C
Video.Mode.NumberOfImagePages		equ 0x1D
Video.Mode.Reserved					equ 0x1E
Video.Mode.LFB						equ 0x28

Video.VGAInfo.Signature				equ 0x00
Video.VGAInfo.Version				equ 0x04
Video.VGAInfo.PointerToOEM			equ 0x06
Video.VGAInfo.Capabilities			equ 0x0A
Video.VGAInfo.VideoModePtr			equ 0x0E
Video.VGAInfo.VideoMemory			equ 0x12


;=====================================================================================
; GLOBAL VARIABLES
;=====================================================================================

Globals.DriveNumber					equ 0x3200 ;SIZE IS 1 BYTE (NEXT: 0x3201)