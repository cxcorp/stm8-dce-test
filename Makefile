#**********************************************************#
#file     makefile
#author   Rajmund Szymanski
#date     06.09.2018
#brief    STM8 makefile.
#**********************************************************#

SDCC       := 

#----------------------------------------------------------#

PROJECT    ?=
DEFS       ?=
DIRS       ?= 
INCS       ?=
LIBS       ?=
KEYS       ?=
SCRIPT     ?=

#----------------------------------------------------------#

DEFS       += STM8S103
KEYS       += .sdcc .stm8 .stm8s *
LIBS       += 

#----------------------------------------------------------#

CC         := sdcc
LD         := stm8-ld
AS         := stm8-as

#----------------------------------------------------------#

DTREE       = $(foreach d,$(foreach k,$(KEYS),$(wildcard $1$k)),$(dir $d) $(call DTREE,$d/))

VPATH      := $(sort $(call DTREE,) $(foreach d,$(DIRS),$(call DTREE,$d/)))

#----------------------------------------------------------#

INC_DIRS   := $(sort $(dir $(foreach d,$(VPATH),$(wildcard $d*.h))))
LIB_DIRS   := $(sort $(dir $(foreach d,$(VPATH),$(wildcard $d*.lib))))
AS_SRCS    :=              $(foreach d,$(VPATH),$(wildcard $d*.s))
CC_SRCS    :=              $(foreach d,$(VPATH),$(wildcard $d*.c))
LIB_SRCS   :=     $(notdir $(foreach d,$(VPATH),$(wildcard $d*.lib)))

ifeq ($(strip $(PROJECT)),)
PROJECT    :=     $(notdir $(CURDIR))
endif

#----------------------------------------------------------#

OBJ_DIR    := obj
ELF        := $(OBJ_DIR)/$(PROJECT).elf
HEX        := $(OBJ_DIR)/$(PROJECT).hex
LIB        := $(OBJ_DIR)/$(PROJECT).lib
MAP        := $(OBJ_DIR)/$(PROJECT).map
CDB        := $(OBJ_DIR)/$(PROJECT).cdb
LKF        := $(OBJ_DIR)/$(PROJECT).lk

OBJS       := $(addprefix $(OBJ_DIR)/,$(CC_SRCS:.c=.o))
ASMS       := $(OBJS:.o=.asm)
LSTS       := $(OBJS:.o=.lst)
RSTS       := $(OBJS:.o=.rst)
SYMS       := $(OBJS:.o=.sym)
ADBS       := $(OBJS:.o=.adb)
DEPS       := $(OBJS:.o=.d)

#----------------------------------------------------------#

AS_FLAGS    = 
CC_FLAGS    = -mstm8 --out-fmt-elf -c --opt-code-size --asm=gas --function-sections --data-sections
LD_FLAGS    = -T./elf32stm8s003f3.x --print-memory-usage --gc-sections -Map $(OBJ_DIR)/map_$(PROJECT).map

#----------------------------------------------------------#

DEFS_F     := $(DEFS:%=-D%)

INC_DIRS   += $(INCS:%=%/)
INC_DIRS_F := $(INC_DIRS:%/=-I%)

SRC_DIRS   := $(sort $(dir $(AS_SRCS) $(CC_SRCS)))
SRC_DIRS_F := $(SRC_DIRS:%/=--directory=%)

LIB_DIRS_F := $(LIB_DIRS:%/=-L%)
LIBS_F     := $(LIBS:%=-l%)
LIBS_F     += $(LIB_SRCS:%.lib=-l%)

AS_FLAGS   +=
CC_FLAGS   += $(DEFS_F) $(INC_DIRS_F)
LD_FLAGS   += $(LIBS_F) $(LIB_DIRS_F)

#----------------------------------------------------------#

all : $(ELF)


$(ELF) : $(OBJS)
	$(info Linking target: $(ELF))
	$(LD) $^ -o $@ $(LD_FLAGS)

$(OBJS) : $(MAKEFILE_LIST)

$(OBJ_DIR)/%.d: %.c
	@mkdir -p $(@D)
	$(CC) $< $(CC_FLAGS) -MM > $@

$(OBJ_DIR)/%.o: %.c $(OBJ_DIR)/%.d
	@mkdir -p $(@D)
	$(CC) $< $(CC_FLAGS) -o $@

$(OBJ_DIR)/%.o: %.asm
	@mkdir -p $(@D)
	$(AS) $< $(AS_FLAGS) -o $@

#%.rel : %.s
#	$(info Assembling file: $<)
#	$(AS) $(AS_FLAGS) $@ $<
#
#%.rel : %.c
#	$(info Compiling file: $<)
#	$(CC) -c $(CC_FLAGS) $< -o $@
#
#$(HEX) : $(OBJS)
#	$(info Creating HEX image: $(HEX))
#	$(CC) $(LD_FLAGS) $(OBJS) -o $@

GENERATED = $(BIN) $(ELF) $(HEX) $(LIB) $(LSS) $(MAP) $(CDB) $(LKF) $(LSTS) $(OBJS) $(ASMS) $(DEPS) $(LSTS) $(RSTS) $(SYMS) $(ADBS)

clean :
	$(info Removing all generated output files)
	rm -f $(GENERATED)

#flash : all $(HEX)
#	$(info Programing device...)
#	$(STVP) -FileProg=$(HEX)


.PHONY : all clean

-include $(DEPS)