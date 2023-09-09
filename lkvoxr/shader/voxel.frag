
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
uniform vec2 texAtlasUVs[32];
uniform ivec2 texAtlasSizes[32];
uniform int voxIDToTexLUT[32];

const int STEPS = 96;
const vec3 worldUp = vec3(0.0, -1.0, 0.0);


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
};

struct voxelQuery {
    bool hasVoxel;
    vec3 col;
    int id;
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

const float sideMul[4] = float[4](1.0, 0.95, 0.85, 0.75);


vec3 textureFunc(vec3 norm, vec3 pos, vec3 rayDir, vec3 col, int side, int id) {
    /*
    vec3 lightDir = normalize(vec3(-1.0, 3.0, -1.0));
    float diffuseAttn = max(dot(norm, lightDir), 0.0);
    vec3 light = vec3(1.0,0.9,0.9);
    
    vec3 ambient = vec3(0.2, 0.2, 0.3);
    
    vec3 reflected = reflect(rayDir, norm);
    float specularAttn = max(dot(reflected, lightDir), 0.0);
    */

    int texID = voxIDToTexLUT[id];
    
    ivec2 texSize = texAtlasSizes[texID];
    vec2 texOffset = texAtlasUVs[texID];



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

    cont = cont * sideMul[side];

    float dotMul = -dot(norm, rayDir);


    //vec4 cont = vec4(uv.x, uv.y, 0.0, 1.0);
    return cont.xyz;// * max(dotMul, 0.0); // * (diffuseAttn*light*1.0 + specularAttn*light*0.6 + ambient);
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
    for (int i = 0; i < STEPS; i++) {
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

            return hitResult(true, textureFunc(norm, pos, rayDir, h.col, side, h.id), pos, norm, h.id);
        }
    }



    return hitResult(false, vec3(0, 0, 0), vec3(0, 0, 0), vec3(0, 1, 0), 0);
}


vec4 effect(vec4 color, Image tex, vec2 textureCoords, vec2 screenCoords) {
    /*
    vec2 uv = screenCoords / screenSize.xy;
    vec4 cont = Texel(chunkConts, vec3(uv.xy, indTestAdd));
    cont.w = 1;

    return cont;
    */


    vec2 uv = screenCoords / screenSize.xy - 0.5;

    vec3 camDir = normalize(camLookAt - camPos);
    vec3 camRight = normalize(cross(camDir, worldUp));
    vec3 camUp = cross(camRight, camDir);
    
    vec3 filmCentre = camPos + camDir*0.3;
    vec2 filmSize = vec2(1, screenSize.y / screenSize.x);
    
    vec3 filmPos = filmCentre + uv.x*filmSize.x*camRight + uv.y*filmSize.y*camUp;
    vec3 ro = camPos; //fract(camPos) - ivec3(renderDistHalf);
    vec3 rd = normalize(filmPos - camPos);


    hitResult data = intersectLK(ro, rd);
    if(data.didHit) {
        vec3 lightDir = normalize(vec3(1.5, 3.0, 1.0));
        vec3 sunRayPos = data.pos + (data.norm * 0.0001);

        hitResult sunRay = intersectLK(sunRayPos, lightDir);
        if(sunRay.didHit) {
            return vec4(data.col * 0.25, 1.0);
        } else {
            return vec4(data.col, 1.0);
        }
    } else {
        float dotVal = rd[1] + 1;
		float colBR = 32 + dotVal * 64;
		float colBG = 48 + dotVal * 96;
		float colBB = 64 + dotVal * 128;


        return vec4(colBR / 255, colBG / 255, colBB / 255, 1.0);
    }
}