uniform float time;
uniform int steps;

uniform bool doFog;
uniform vec3 fogColour;

uniform bool doBlockShade;
uniform float blockShadeList[4];

uniform bool doShadows;
uniform vec3 shadowDir;


uniform vec3 camPos;
uniform vec3 camLookAt;
uniform float camFOV;
uniform vec2 screenSize;

const int CHUNKSEND_COUNT = 64;

uniform VolumeImage chunkList[CHUNKSEND_COUNT];
uniform vec3 chunkOrigins[CHUNKSEND_COUNT];
uniform vec3 chunkSize;
uniform vec3 chunkSizeLarge;
uniform int chunkCount;

uniform Image texAtlas;
uniform vec2 texAtlasSize;
uniform vec2 texAtlasUVs[48];
uniform ivec2 texAtlasSizes[48];

uniform Image texCloud;
uniform int texCloudSz;

const vec3 worldUp = vec3(0.0, -1.0, 0.0);


struct hit {
    bool didHit;
    vec3 col;
    int id;
};

struct hitResult {
    bool didHit;
    vec3 col;
    vec3 pos;
    vec3 norm;
    int id;
    float dist;
};

struct voxelQuery {
    bool hasVoxel;
    vec3 col;
    int id;
};

struct planeIntersectResult {
    bool didHit;
    vec3 pos;
};



bool inrange(int v, int minv, int maxv) {
    return v >= minv && v <= maxv;
}

float insideBox3D(vec3 v, vec3 bottomLeft, vec3 topRight) {
    vec3 s = step(bottomLeft, v) - step(topRight, v);
    return s.x * s.y * s.z; 
}


int col2id(vec3 col) {
    return int(((col.x * 255) * 65536) + ((col.y * 255) * 256) + (col.z * 255));
}


//https://www.shadertoy.com/view/wdSBzK
voxelQuery getVoxel(ivec3 p) {
    int chunkInd = 5120;
    for (int i = 0; i < chunkCount; i++) {
        vec3 origin = chunkOrigins[i];
        vec3 minPos = origin;
        vec3 maxPos = origin + chunkSizeLarge;

        if(insideBox3D(p, minPos, maxPos) == 1.0) {
            chunkInd = i;
            break;
        }
    }

    if (chunkInd == 5120) 
        return voxelQuery(false, vec3(0.0, 0.0, 0.0), 0);

    vec3 sample = p.xzy;
    //sample.y = (chunkSize.z * 1) - sample.y;
    sample -= chunkOrigins[chunkInd].xzy;
    //sample -= chunkSize * 2;


    vec4 cont = Texel(chunkList[chunkInd], sample / chunkSize.xzy);
    int id = col2id(vec3(cont.xyz));

    /*
    vec3 sample = p.xzy;
    sample.y = (renderDistHalf * 2) - p.y;
    vec4 cont = Texel(chunkConts, sample / (vec3(renderDistHalf) * 2));
    */


    vec3 col = vec3(0, 0, id); //vec4(abs(sample.xyz / chunkSize.xzy), 0.0);
    if (id != 0)
        return voxelQuery(true , col.xyz, id);
    else
        return voxelQuery(false, vec3(0.0, 0.0, 0.0), 0);
}

vec3 textureFunc(vec3 norm, vec3 pos, vec3 rayDir, vec3 col, int side, int id, float dist) {
    /*
    vec3 lightDir = normalize(vec3(-1.0, 3.0, -1.0));
    float diffuseAttn = max(dot(norm, lightDir), 0.0);
    vec3 light = vec3(1.0,0.9,0.9);
    
    vec3 ambient = vec3(0.2, 0.2, 0.3);
    
    vec3 reflected = reflect(rayDir, norm);
    float specularAttn = max(dot(reflected, lightDir), 0.0);
    */

    //int texID = voxIDToTexLUT[id];
    
    ivec2 texSize = ivec2(texAtlasSizes[id - 1]);
    vec2 texOffset = vec2(texAtlasUVs[id - 1]);



    float tx = abs(mod(pos.x, 1));
    float ty = abs(mod(pos.y, 1));
    float tz = abs(mod(pos.z, 1));

    vec2 uv = vec2(0, 0);
    if(side == 1) {
		uv = vec2(
            tz,
            (1 - ty)
        );
    } else if(side == 2) {
        uv = vec2(
            tx,
		    tz
        );
    } else {
        uv = vec2(
		    tx,
		    (1 - ty)
        );
    }

    // / atlas_size
    vec2 texCoord = texOffset + (uv * texSize);
    vec4 cont = Texel(texAtlas, texCoord / texAtlasSize);

    cont *= doBlockShade ? blockShadeList[side] : 1;

    return cont.xyz;
}

hitResult intersectLK(vec3 rayPos, vec3 rayDir) {
    vec3 mapPos = floor(rayPos);

    vec3 deltaDist = abs(1 / rayDir);

    vec3 stepD;
    vec3 sideDist;

    // TODO: replace these with ? and :
    if (rayDir.x < 0) {
		stepD.x = -1;
		sideDist.x = (rayPos.x - mapPos.x) * deltaDist.x;
	} else {
		stepD.x = 1;
		sideDist.x = (mapPos.x + 1.0 - rayPos.x) * deltaDist.x;
	}

	if (rayDir.y < 0) {
		stepD.y = -1;
		sideDist.y = (rayPos.y - mapPos.y) * deltaDist.y;
	} else {
		stepD.y = 1;
		sideDist.y = (mapPos.y + 1.0 - rayPos.y) * deltaDist.y;
	}

	if (rayDir.z < 0) {
		stepD.z = -1;
		sideDist.z = (rayPos.z - mapPos.z) * deltaDist.z;
	} else {
		stepD.z = 1;
		sideDist.z = (mapPos.z + 1.0 - rayPos.z) * deltaDist.z;
	}

    int side;
    for (int i = 0; i < steps; i++) {
        if (sideDist.x < sideDist.y) {
            if (sideDist.x < sideDist.z) {
                sideDist.x += deltaDist.x;
				mapPos.x += stepD.x;
				side = 1;
            } else {
                sideDist.z += deltaDist.z;
			    mapPos.z += stepD.z;
			    side = 3;
            }
        } else {
            if (sideDist.y < sideDist.z) {
                sideDist.y += deltaDist.y;
			    mapPos.y += stepD.y;
			    side = 2;
            } else {
                sideDist.z += deltaDist.z;
			    mapPos.z += stepD.z;
			    side = 3;
            }
        }


        voxelQuery h = getVoxel(ivec3(mapPos));
        if(h.hasVoxel) {
            float perpWallDist = 0;
            vec3 norm = vec3(0, 0, 0);
            if (side == 1) {
                perpWallDist = sideDist.x - deltaDist.x;
                norm.x = -stepD.x;
            } else if (side == 2) {
                perpWallDist = sideDist.y - deltaDist.y;
                norm.y = -stepD.y;
            } else {
                perpWallDist = sideDist.z - deltaDist.z;
                norm.z = -stepD.z;
            }

            vec3 pos = (rayDir * perpWallDist);
            pos += rayPos;

            float dist = distance(rayPos, pos);

            return hitResult(true, textureFunc(norm, pos, rayDir, h.col, side, h.id, perpWallDist), pos, norm, h.id, perpWallDist);
        }
    }

    return hitResult(false, vec3(0, 0, 0), vec3(0, 0, 0), vec3(0, 1, 0), 0, 1e32);
}


vec3 getDir(vec2 screenCords, vec2 screenSize, vec2 uv) {
    float coeff = tan((camFOV / 2) * (3.1416 / 180)) * 2.71828;
	return normalize(vec3(
        ((screenSize.x - screenCords.x) / (screenSize.x - 1) - 0.5) * coeff,
        -1,
		(coeff / screenSize.x) * (screenSize.y - screenCords.y) - 0.5 * (coeff / screenSize.x) * (screenSize.y - 1)
	));
}

vec3 rayDirection(float fieldOfView, vec2 size, vec2 fragCoord) {
    vec2 xy = fragCoord - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

mat4 viewMatrix(vec3 eye, vec3 center, vec3 up) {
	vec3 f = normalize(center - eye);
	vec3 s = normalize(cross(f, up));
	vec3 u = cross(s, f);
	return mat4(
		vec4(s, 0.0),
		vec4(u, 0.0),
		vec4(-f, 0.0),
		vec4(0.0, 0.0, 0.0, 1)
	);
}


// https://discourse.vvvv.org/t/infinite-ray-intersects-with-infinite-plane/10537
planeIntersectResult IntersectRayPlane(vec3 rayOrigin, vec3 rayDirection, vec3 posOnPlane, vec3 planeNormal) {
  float rDotn = dot(rayDirection, planeNormal);

  //parallel to plane or pointing away from plane?
  if (rDotn < 0.0000001 )
    return planeIntersectResult(false, vec3(0, 0, 0));
 
  float s = dot(planeNormal, (posOnPlane - rayOrigin)) / rDotn;
	
  vec3 intersectionPoint = rayOrigin + s * rayDirection;

  return planeIntersectResult(true, intersectionPoint);
}

vec4 effect(vec4 color, Image tex, vec2 textureCoords, vec2 screenCoords) {

    vec2 uv = screenCoords / screenSize.xy - 0.5;

    vec3 camDir = normalize(camLookAt - camPos);
    vec3 ro = camPos;

    mat4 matrixCam = viewMatrix(vec3(0, 0, 0), camDir, worldUp);
    vec3 scrDir = getDir(screenCoords, screenSize, uv).xzy;
    scrDir.x = -scrDir.x;
    scrDir.y = -scrDir.y;

    vec3 rd = (matrixCam * vec4(scrDir, 1.0)).xyz;




    vec3 albedo = vec3(0, 0, 0);
    hitResult data = intersectLK(ro, rd);
    if(data.didHit) {

        if(doShadows) {
            vec3 sunRayPos = data.pos + (data.norm * 0.0001);
            hitResult sunRay = intersectLK(sunRayPos, shadowDir);
            data.col *= sunRay.didHit ? 0.25 : 1;
        }


        vec3 camDirInv = vec3(camDir);
        mat4 matrixCamInv = viewMatrix(vec3(0, 0, 0), camDirInv, worldUp);


        if(doFog) {
            float distDiv = min(data.dist / (steps * 0.5), 1);
            data.col = mix(data.col, fogColour, distDiv);
        }

        return vec4(data.col, 1.0);
    } else {

        float dotVal = rd[1] + 1;
        vec3 colSky = vec3(32 + dotVal * 64, 48 + dotVal * 96, 64 + dotVal * 128);


        float dotSun = (max(dot(rd, shadowDir) - 0.985, 0) * 100);
        vec3 colSun = vec3(dotSun * 128, dotSun * 64, dotSun * 16);


        vec3 posPlane = vec3(-ro.x, -ro.y, -ro.z);
        int normAxis = ro.y - 128 > 0 ? -1 : 1;
        planeIntersectResult skyIntersect = IntersectRayPlane(posPlane, rd, vec3(0, -128, 0), vec3(0, normAxis, 0));


        vec3 colCombined = (colSky + colSun) / 255;
        if(skyIntersect.didHit) {
            vec2 texUV = skyIntersect.pos.xz / 256;

            vec4 contCloud = Texel(texCloud, texUV + vec2(time * 0.025, time * 0.0425));
            float cloudIntensity = contCloud.r;

            vec3 preFinalCloudCol = mix(colCombined, contCloud.xyz, cloudIntensity);


            if(doFog) {
                float dist = distance(skyIntersect.pos, ro) / 16;
                float distDiv = min(dist / (steps * 0.5), 1);

                preFinalCloudCol = mix(preFinalCloudCol, colCombined, distDiv);
            }



            return vec4(preFinalCloudCol, 1.0);
        }
        
        return vec4((colSky + colSun) / 255, 1.0);
    }
}