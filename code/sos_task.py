#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
This experiment was created using PsychoPy3 Experiment Builder (v3.0.0b7),
    on January 17, 2019, at 13:33
If you publish work using this script please cite the PsychoPy publications:
    Peirce, JW (2007) PsychoPy - Psychophysics software in Python.
        Journal of Neuroscience Methods, 162(1-2), 8-13.
    Peirce, JW (2009) Generating stimuli for neuroscience using PsychoPy.
        Frontiers in Neuroinformatics, 2:10. doi: 10.3389/neuro.11.010.2008
"""

from __future__ import absolute_import, division
from psychopy import locale_setup, sound, gui, visual, core, data, event, logging, clock
from psychopy.constants import (
    NOT_STARTED,
    STARTED,
    PLAYING,
    PAUSED,
    STOPPED,
    FINISHED,
    PRESSED,
    RELEASED,
    FOREVER,
)
import numpy as np  # whole numpy lib is available, prepend 'np.'
from numpy import (
    sin,
    cos,
    tan,
    log,
    log10,
    pi,
    average,
    sqrt,
    std,
    deg2rad,
    rad2deg,
    linspace,
    asarray,
)
from numpy.random import random, randint, normal, shuffle
import os  # handy system and path functions
import sys  # to get file system encoding

# Ensure that relative paths start from the same directory as this script
_thisDir = os.path.dirname(os.path.abspath(__file__))
os.chdir(_thisDir)

# Store info about the experiment session
expName = "sos"  # from the Builder filename that created this script
expInfo = {"TAG ID": "TAGxxx", "Wave": "sos"}
dlg = gui.DlgFromDict(dictionary=expInfo, title=expName)
if dlg.OK == False:
    core.quit()  # user pressed cancel
expInfo["date"] = data.getDateStr()  # add a simple timestamp
expInfo["expName"] = expName

# Data file name stem = absolute path + name; later add .psyexp, .csv, .log, etc
filename = (
    _thisDir + os.sep + "data/%s_%s_%s" % (expInfo["TAG ID"], expName, expInfo["date"])
)

# An ExperimentHandler isn't essential but helps with data saving
thisExp = data.ExperimentHandler(
    name=expName,
    version="",
    extraInfo=expInfo,
    runtimeInfo=None,
    originPath="C:\\Users\\mbyrne\\Documents\\SOS\\TIM_Scanner\\sos_txt.py",
    savePickle=True,
    saveWideText=True,
    dataFileName=filename,
)
# save a log file for detail verbose info
logFile = logging.LogFile(filename + ".log", level=logging.EXP)
logging.console.setLevel(logging.WARNING)  # this outputs to the screen, not a file

endExpNow = False  # flag for 'escape' or other condition => quit the exp

# Start Code - component code to be run before the window creation

# Setup the Window
win = visual.Window(
    size=[1366, 768],
    fullscr=True,
    screen=0,
    allowGUI=False,
    allowStencil=False,
    monitor="testMonitor",
    color=[-1.000, -1.000, -1.000],
    colorSpace="rgb",
    blendMode="avg",
    useFBO=True,
)
# store frame rate of monitor if we can measure it
expInfo["frameRate"] = win.getActualFrameRate()
if expInfo["frameRate"] != None:
    frameDur = 1.0 / round(expInfo["frameRate"])
else:
    frameDur = 1.0 / 60.0  # could not measure, so guess

# Initialize components for Routine "wait"
waitClock = core.Clock()
sync = visual.TextStim(
    win=win,
    name="sync",
    text="Syncing with off-site scanner...",
    font="Arial",
    pos=(0, 0),
    height=0.125,
    wrapWidth=None,
    ori=0,
    color="white",
    colorSpace="rgb",
    opacity=1,
    languageStyle="LTR",
    depth=0.0,
)
# Initialize components for Routine "rest"
restClock = core.Clock()

cross = visual.ShapeStim(
    win=win,
    name="cross",
    vertices="cross",
    size=(0.1, 0.1778),
    ori=0,
    pos=(0, 0),
    lineWidth=0,
    lineColor=[1, 1, 1],
    lineColorSpace="rgb",
    fillColor=[1, 1, 1],
    fillColorSpace="rgb",
    opacity=1,
    depth=-1.0,
    interpolate=True,
)

# Initialize components for Routine "condition"
conditionClock = core.Clock()

background = visual.Rect(
    win=win,
    name="background",
    width=(1366, 768)[0],
    height=(1366, 768)[1],
    ori=0,
    pos=(0, 0),
    lineWidth=0,
    lineColor=1.0,
    lineColorSpace="rgb",
    fillColor=1.0,
    fillColorSpace="rgb",
    opacity=1,
    depth=-1.0,
    interpolate=True,
)
cue = visual.TextStim(
    win=win,
    name="cue",
    text="default text",
    font="Arial",
    pos=(0, 0.9375),
    height=0.125,
    wrapWidth=None,
    ori=0,
    color="white",
    colorSpace="rgb",
    opacity=1,
    languageStyle="LTR",
    depth=-3.0,
)
# Initialize components for Routine "rest_end"
rest_endClock = core.Clock()

cross_end = visual.ShapeStim(
    win=win,
    name="cross_end",
    vertices="cross",
    size=(0.1, 0.1778),
    ori=0,
    pos=(0, 0),
    lineWidth=0,
    lineColor=[1, 1, 1],
    lineColorSpace="rgb",
    fillColor=[1, 1, 1],
    fillColorSpace="rgb",
    opacity=1,
    depth=-1.0,
    interpolate=True,
)

# Initialize components for Routine "end"
endClock = core.Clock()
end_run = visual.TextStim(
    win=win,
    name="end_run",
    text="Scan Complete!",
    font="Arial",
    pos=(0, 0),
    height=0.125,
    wrapWidth=None,
    ori=0,
    color="white",
    colorSpace="rgb",
    opacity=1,
    languageStyle="LTR",
    depth=0.0,
)
# Create some handy timers
globalClock = core.Clock()  # to track the time since experiment started
routineTimer = (
    core.CountdownTimer()
)  # to track time remaining of each (non-slip) routine

# ------Prepare to start Routine "wait"-------
t = 0
waitClock.reset()  # clock
frameN = -1
continueRoutine = True
# update component parameters for each repeat
trigger = event.BuilderKeyResponse()
# keep track of which components have finished
waitComponents = [sync, trigger]
for thisComponent in waitComponents:
    if hasattr(thisComponent, "status"):
        thisComponent.status = NOT_STARTED

# -------Start Routine "wait"-------
while continueRoutine:
    # get current time
    t = waitClock.getTime()
    frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
    # update/draw components on each frame

    # *sync* updates
    if t >= 0.0 and sync.status == NOT_STARTED:
        # keep track of start time/frame for later
        sync.tStart = t
        sync.frameNStart = frameN  # exact frame index
        sync.setAutoDraw(True)

    # *trigger* updates
    if t >= 0.0 and trigger.status == NOT_STARTED:
        # keep track of start time/frame for later
        trigger.tStart = t
        trigger.frameNStart = frameN  # exact frame index
        trigger.status = STARTED
        # keyboard checking is just starting
        win.callOnFlip(trigger.clock.reset)  # t=0 on next screen flip
        event.clearEvents(eventType="keyboard")
    if trigger.status == STARTED:
        theseKeys = event.getKeys(keyList=["apostrophe"])

        # check for quit:
        if "escape" in theseKeys:
            endExpNow = True
        if len(theseKeys) > 0:  # at least one key was pressed
            trigger.keys = theseKeys[-1]  # just the last key pressed
            trigger.rt = trigger.clock.getTime()
            # a response ends the routine
            continueRoutine = False

    # check if all components have finished
    if not continueRoutine:  # a component has requested a forced-end of Routine
        break
    continueRoutine = (
        False  # will revert to True if at least one component still running
    )
    for thisComponent in waitComponents:
        if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
            continueRoutine = True
            break  # at least one component has not yet finished

    # check for quit (the Esc key)
    if endExpNow or event.getKeys(keyList=["escape"]):
        core.quit()

    # refresh the screen
    if (
        continueRoutine
    ):  # don't flip if this routine is over or we'll get a blank screen
        win.flip()

# -------Ending Routine "wait"-------
for thisComponent in waitComponents:
    if hasattr(thisComponent, "setAutoDraw"):
        thisComponent.setAutoDraw(False)
# check responses
if trigger.keys in ["", [], None]:  # No response was made
    trigger.keys = None
thisExp.addData("trigger.keys", trigger.keys)
if trigger.keys != None:  # we had a response
    thisExp.addData("trigger.rt", trigger.rt)
thisExp.nextEntry()
# the Routine "wait" was not non-slip safe, so reset the non-slip timer
routineTimer.reset()

# set up handler to look after randomisation of conditions etc
trials_loop = data.TrialHandler(
    nReps=1,
    method="sequential",
    extraInfo=expInfo,
    originPath=-1,
    trialList=data.importConditions("trialorder.csv"),
    seed=None,
    name="trials_loop",
)
thisExp.addLoop(trials_loop)  # add the loop to the experiment
thisTrials_loop = trials_loop.trialList[
    0
]  # so we can initialise stimuli with some values
# abbreviate parameter names if possible (e.g. rgb = thisTrials_loop.rgb)
if thisTrials_loop != None:
    for paramName in thisTrials_loop:
        exec("{} = thisTrials_loop[paramName]".format(paramName))

for thisTrials_loop in trials_loop:
    currentLoop = trials_loop
    # abbreviate parameter names if possible (e.g. rgb = thisTrials_loop.rgb)
    if thisTrials_loop != None:
        for paramName in thisTrials_loop:
            exec("{} = thisTrials_loop[paramName]".format(paramName))

    # ------Prepare to start Routine "rest"-------
    t = 0
    restClock.reset()  # clock
    frameN = -1
    continueRoutine = True
    # update component parameters for each repeat
    thisExp.addData("rest_onset", (globalClock.getTime() - trigger.rt))

    # keep track of which components have finished
    restComponents = [cross]
    for thisComponent in restComponents:
        if hasattr(thisComponent, "status"):
            thisComponent.status = NOT_STARTED

    # -------Start Routine "rest"-------
    while continueRoutine:
        # get current time
        t = restClock.getTime()
        frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
        # update/draw components on each frame

        # *cross* updates
        if t >= 0.0 and cross.status == NOT_STARTED:
            # keep track of start time/frame for later
            cross.tStart = t
            cross.frameNStart = frameN  # exact frame index
            cross.setAutoDraw(True)
        frameRemains = (
            0.0 + DurationRest - win.monitorFramePeriod * 0.75
        )  # most of one frame period left
        if cross.status == STARTED and t >= frameRemains:
            cross.setAutoDraw(False)

        # check if all components have finished
        if not continueRoutine:  # a component has requested a forced-end of Routine
            break
        continueRoutine = (
            False  # will revert to True if at least one component still running
        )
        for thisComponent in restComponents:
            if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
                continueRoutine = True
                break  # at least one component has not yet finished

        # check for quit (the Esc key)
        if endExpNow or event.getKeys(keyList=["escape"]):
            core.quit()

        # refresh the screen
        if (
            continueRoutine
        ):  # don't flip if this routine is over or we'll get a blank screen
            win.flip()

    # -------Ending Routine "rest"-------
    for thisComponent in restComponents:
        if hasattr(thisComponent, "setAutoDraw"):
            thisComponent.setAutoDraw(False)
    thisExp.addData("rest_duration", t)
    # the Routine "rest" was not non-slip safe, so reset the non-slip timer
    routineTimer.reset()

    # ------Prepare to start Routine "condition"-------
    t = 0
    conditionClock.reset()  # clock
    frameN = -1
    continueRoutine = True
    # update component parameters for each repeat
    thisExp.addData("block_onset", (globalClock.getTime() - trigger.rt))
    background.setFillColor(Color)
    background.setLineColor(Color)
    clip = visual.MovieStim3(
        win=win,
        name="clip",
        noAudio=False,
        filename=Path,
        ori=0,
        pos=(0, 0),
        opacity=1,
        size=(1184, 666),
        depth=-2.0,
    )
    cue.setText(Cue)
    # keep track of which components have finished
    conditionComponents = [background, clip, cue]
    for thisComponent in conditionComponents:
        if hasattr(thisComponent, "status"):
            thisComponent.status = NOT_STARTED

    # -------Start Routine "condition"-------
    while continueRoutine:
        # get current time
        t = conditionClock.getTime()
        frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
        # update/draw components on each frame

        # *background* updates
        if t >= 0.0 and background.status == NOT_STARTED:
            # keep track of start time/frame for later
            background.tStart = t
            background.frameNStart = frameN  # exact frame index
            background.setAutoDraw(True)
        frameRemains = (
            0.0 + Duration - win.monitorFramePeriod * 0.75
        )  # most of one frame period left
        if background.status == STARTED and t >= frameRemains:
            background.setAutoDraw(False)

        # *clip* updates
        if t >= 0.0 and clip.status == NOT_STARTED:
            # keep track of start time/frame for later
            clip.tStart = t
            clip.frameNStart = frameN  # exact frame index
            clip.setAutoDraw(True)
        frameRemains = (
            0.0 + Duration - win.monitorFramePeriod * 0.75
        )  # most of one frame period left
        if clip.status == STARTED and t >= frameRemains:
            clip.setAutoDraw(False)

        # *cue* updates
        if t >= 0.0 and cue.status == NOT_STARTED:
            # keep track of start time/frame for later
            cue.tStart = t
            cue.frameNStart = frameN  # exact frame index
            cue.setAutoDraw(True)
        frameRemains = (
            0.0 + Duration - win.monitorFramePeriod * 0.75
        )  # most of one frame period left
        if cue.status == STARTED and t >= frameRemains:
            cue.setAutoDraw(False)

        # check if all components have finished
        if not continueRoutine:  # a component has requested a forced-end of Routine
            break
        continueRoutine = (
            False  # will revert to True if at least one component still running
        )
        for thisComponent in conditionComponents:
            if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
                continueRoutine = True
                break  # at least one component has not yet finished

        # check for quit (the Esc key)
        if endExpNow or event.getKeys(keyList=["escape"]):
            core.quit()

        # refresh the screen
        if (
            continueRoutine
        ):  # don't flip if this routine is over or we'll get a blank screen
            win.flip()

    # -------Ending Routine "condition"-------
    for thisComponent in conditionComponents:
        if hasattr(thisComponent, "setAutoDraw"):
            thisComponent.setAutoDraw(False)
    thisExp.addData("block_duration", t)
    # the Routine "condition" was not non-slip safe, so reset the non-slip timer
    routineTimer.reset()
    thisExp.nextEntry()

# completed 1 repeats of 'trials_loop'


# ------Prepare to start Routine "rest_end"-------
t = 0
rest_endClock.reset()  # clock
frameN = -1
continueRoutine = True
routineTimer.add(10.986930)
# update component parameters for each repeat
thisExp.addData("rest_onset", (globalClock.getTime() - trigger.rt))
# keep track of which components have finished
rest_endComponents = [cross_end]
for thisComponent in rest_endComponents:
    if hasattr(thisComponent, "status"):
        thisComponent.status = NOT_STARTED

# -------Start Routine "rest_end"-------
while continueRoutine and routineTimer.getTime() > 0:
    # get current time
    t = rest_endClock.getTime()
    frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
    # update/draw components on each frame

    # *cross_end* updates
    if t >= 0.0 and cross_end.status == NOT_STARTED:
        # keep track of start time/frame for later
        cross_end.tStart = t
        cross_end.frameNStart = frameN  # exact frame index
        cross_end.setAutoDraw(True)
    frameRemains = (
        0.0 + 10.98693 - win.monitorFramePeriod * 0.75
    )  # most of one frame period left
    if cross_end.status == STARTED and t >= frameRemains:
        cross_end.setAutoDraw(False)

    # check if all components have finished
    if not continueRoutine:  # a component has requested a forced-end of Routine
        break
    continueRoutine = (
        False  # will revert to True if at least one component still running
    )
    for thisComponent in rest_endComponents:
        if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
            continueRoutine = True
            break  # at least one component has not yet finished

    # check for quit (the Esc key)
    if endExpNow or event.getKeys(keyList=["escape"]):
        core.quit()

    # refresh the screen
    if (
        continueRoutine
    ):  # don't flip if this routine is over or we'll get a blank screen
        win.flip()

# -------Ending Routine "rest_end"-------
for thisComponent in rest_endComponents:
    if hasattr(thisComponent, "setAutoDraw"):
        thisComponent.setAutoDraw(False)
thisExp.addData("rest_duration", t)

# ------Prepare to start Routine "end"-------
t = 0
endClock.reset()  # clock
frameN = -1
continueRoutine = True
# update component parameters for each repeat
exit = event.BuilderKeyResponse()
# keep track of which components have finished
endComponents = [end_run, exit]
for thisComponent in endComponents:
    if hasattr(thisComponent, "status"):
        thisComponent.status = NOT_STARTED

# -------Start Routine "end"-------
while continueRoutine:
    # get current time
    t = endClock.getTime()
    frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
    # update/draw components on each frame

    # *end_run* updates
    if t >= 0.0 and end_run.status == NOT_STARTED:
        # keep track of start time/frame for later
        end_run.tStart = t
        end_run.frameNStart = frameN  # exact frame index
        end_run.setAutoDraw(True)

    # *exit* updates
    if t >= 0.0 and exit.status == NOT_STARTED:
        # keep track of start time/frame for later
        exit.tStart = t
        exit.frameNStart = frameN  # exact frame index
        exit.status = STARTED
        # keyboard checking is just starting
        win.callOnFlip(exit.clock.reset)  # t=0 on next screen flip
        event.clearEvents(eventType="keyboard")
    if exit.status == STARTED:
        theseKeys = event.getKeys(keyList=["space"])

        # check for quit:
        if "escape" in theseKeys:
            endExpNow = True
        if len(theseKeys) > 0:  # at least one key was pressed
            exit.keys = theseKeys[-1]  # just the last key pressed
            exit.rt = exit.clock.getTime()
            # a response ends the routine
            continueRoutine = False

    # check if all components have finished
    if not continueRoutine:  # a component has requested a forced-end of Routine
        break
    continueRoutine = (
        False  # will revert to True if at least one component still running
    )
    for thisComponent in endComponents:
        if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
            continueRoutine = True
            break  # at least one component has not yet finished

    # check for quit (the Esc key)
    if endExpNow or event.getKeys(keyList=["escape"]):
        core.quit()

    # refresh the screen
    if (
        continueRoutine
    ):  # don't flip if this routine is over or we'll get a blank screen
        win.flip()

# -------Ending Routine "end"-------
for thisComponent in endComponents:
    if hasattr(thisComponent, "setAutoDraw"):
        thisComponent.setAutoDraw(False)
# check responses
if exit.keys in ["", [], None]:  # No response was made
    exit.keys = None
thisExp.addData("exit.keys", exit.keys)
if exit.keys != None:  # we had a response
    thisExp.addData("exit.rt", exit.rt)
thisExp.nextEntry()
# the Routine "end" was not non-slip safe, so reset the non-slip timer
routineTimer.reset()


# these shouldn't be strictly necessary (should auto-save)
thisExp.saveAsWideText(filename + ".csv")
thisExp.saveAsPickle(filename)
logging.flush()
# make sure everything is closed down
thisExp.abort()  # or data files will save again on exit
win.close()
core.quit()
