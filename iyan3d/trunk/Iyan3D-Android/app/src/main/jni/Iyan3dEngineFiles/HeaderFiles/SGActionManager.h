//
//  SGActionManager.h
//  Iyan3D
//
//  Created by Karthik on 26/12/15.
//  Copyright © 2015 Smackall Games. All rights reserved.
//

#ifndef SGActionManager_h
#define SGActionManager_h

#define MAXUNDO 500

#include "SGAction.h"
#include "Constants.h"

class SGActionManager
{
private:
    SceneManager* smgr;
    SGAction changeKeysAction;
    SGAction propertyAction;
    SGAction assetAction;

    MIRROR_SWITCH_STATE mirrorSwitchState;
    
    void rotateJoint(Vector3 outputValue);
    void StoreDeleteObjectKeys(int nodeIndex);

public:
    
    int currentAction;
    SGAction addJointAction;
    //sabish
    SGAction scaleAction;
    
    vector<SGAction> actions;

    SGActionManager(SceneManager* smgr, void* scene);
    ~SGActionManager();
    int getObjectIndex(int actionIndex);
    void addAction(SGAction& action);
    void finalizeAndAddAction(SGAction& action);
    void removeActions();
    
    /* Move/Rotate node/joint actions */
    
    bool changeObjectOrientation(Vector3 outputValue);
    void moveJoint(Vector3 outputValue, bool touchMove = false);
    bool isIKJoint(int jointId);
    void storeActionKeys(bool finished);
    void storeActionKeysForMulti(bool finished);

    
    /* Scale Mesh*/
    //sabish
    void changeObjectScale(Vector3 scale, bool isChanged);
    
    /* Frames change related actions */
    
    void switchFrame(int frame);
    
    /* Property Change actions */
    
    void changeMeshProperty(float brightness, float specular, bool isLighting, bool isVisible, bool isChanged = false);
    void changeCameraProperty(float fov , int resolutionType, bool isChanged = false);
    void changeLightProperty(float red , float green, float blue, float shadow, bool isChanged = false);
    void storeLightPropertyChangeAction(float red , float green , float blue , float shadowDensity);

    /* Mirror Change action */
    
    void setMirrorState(MIRROR_SWITCH_STATE flag);
    bool switchMirrorState();
    MIRROR_SWITCH_STATE getMirrorState();
    /* Node add or remove actions */
    
    void storeAddOrRemoveAssetAction(int actionType, int assetId, string optionalFilePath = "");
    void removeDemoAnimation();
    /* Undo and Redo*/
    
    int undo(int& returnValue2);
    int redo();
    
    /* AutoRig */
    
    bool changeSkeletonPosition(Vector3 outputValue);
    bool changeSkeletonRotation(Vector3 outputValue);
    bool changeSGRPosition(Vector3 outputValue);
    bool changeSGRRotation(Vector3 outputValue);
};

#endif /* SGActionManager_h */
