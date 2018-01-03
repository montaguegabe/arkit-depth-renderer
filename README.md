# arkit-depth-renderer
Displays the depth values received by the front-facing camera. The depth values are applied to a heat map and multiplied with the camera's color image. The resulting image is then used as the background for the augmented reality scenekit scene.

This example builds upon the official [Creating Face-Based AR Experiences](https://developer.apple.com/documentation/arkit/creating_face_based_ar_experiences) demo and is free to use.

## Overview
- See additions to ViewController.swift
- Depth frames can be accessed by any object that conforms to `ARSessionDelegate` using the `session(_ session: ARSession, didUpdate frame: ARFrame)` method.
- To align SceneKit rendering with the depth image, we use `frame.displayTransform` to get a matrix that is used to properly align the projection.
- The raw frame data can be fed into Core Image for manipulation, for example with `CIImage(cvImageBuffer: depthBuffer)`
- Once in Core Image, a temperature gradient can be applied, and the color image can be multiplied in using filters (see Core Image docs).

Depth frames are not received as quickly as color frames are. As a result, the camera feedback is not as fast as a photo preview would normally be. I haven't been able to find a way to manipulate the camera configuration to increase the rate at which the depth images are recieved.

