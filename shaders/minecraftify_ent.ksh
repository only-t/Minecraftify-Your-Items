   minecraftify_ent      MatrixP                                                                                MatrixV                                                                                MatrixW                                                                                FLOAT_PARAMS                            CAMERARIGHT                         
   TIMEPARAMS                                SAMPLER    +         LIGHTMAP_WORLD_EXTENTS                                COLOUR_XFORM                                                                                PARAMS                            OCEAN_BLEND_PARAMS                                OCEAN_WORLD_EXTENTS                                minecraftify_ent.vsO  // Vertex shader

uniform mat4 MatrixP;
uniform mat4 MatrixV;
uniform mat4 MatrixW;
uniform vec3 FLOAT_PARAMS;

attribute vec4 POS2D_UV; // x, y, u + samplerIndex * 2, v

varying vec3 PS_POS;
varying vec3 PS_TEXCOORD;
varying float FLOATING;
uniform vec3 CAMERARIGHT;

uniform vec4 TIMEPARAMS;

#define ENT_X_FLOOR floor(FLOAT_PARAMS.x)
#define ENT_Y_FLOOR floor(FLOAT_PARAMS.y)
#define ENT_Z_FLOOR floor(FLOAT_PARAMS.z)

#define USE_WORLD_Y (FLOAT_PARAMS.x - ENT_X_FLOOR)

#define PI 3.1415926535897932384626433832795

void main()
{
	vec3 POSITION = vec3(POS2D_UV.xy, 0.0);
	float samplerIndex = floor(POS2D_UV.z / 2.0);
	vec3 TEXCOORD0 = vec3(POS2D_UV.z - 2.0 * samplerIndex, POS2D_UV.w, samplerIndex);

    vec3 entPos = vec3(ENT_X_FLOOR / 1000.0, ENT_Y_FLOOR / 100000.0, ENT_Z_FLOOR / 1000.0);
    float yaw = mod(atan(CAMERARIGHT.z, CAMERARIGHT.x) / (2.0 * PI) + 0.75, 1.0); // Some fun trigonometry
    float pitch = FLOAT_PARAMS.y - ENT_Y_FLOOR;
    vec3 forward = vec3(cos(2.0 * PI * yaw) * cos(2.0 * PI * pitch), sin(-2.0 * PI * pitch), sin(2.0 * PI * yaw) * cos(2.0 * PI * pitch));

	vec4 object_pos = vec4(POSITION.xyz, 1.0);
	vec4 world_pos = MatrixW * object_pos;
    world_pos.xyz -= entPos;

    float angleY = TIMEPARAMS.x + entPos.x * entPos.z * 0.1;
    float rotSin = sin(angleY);
    float rotCos = cos(angleY);
    float nRotCos = 1.0 - rotCos;
    vec3 axisY = cross(CAMERARIGHT, forward);
    axisY.y = -axisY.y;
    mat4 rotY = mat4( // Just some more simple maths
        rotCos + pow(axisY.x, 2.0) * nRotCos, axisY.y * axisY.x * nRotCos + axisY.z * rotSin, axisY.z * axisY.x * nRotCos - axisY.y * rotSin, 0.0,
        axisY.x * axisY.y * nRotCos - axisY.z * rotSin, rotCos + pow(axisY.y, 2.0) * nRotCos, axisY.z * axisY.y * nRotCos + axisY.x * rotSin, 0.0,
        axisY.x * axisY.z * nRotCos + axisY.y * rotSin, axisY.y * axisY.z * nRotCos - axisY.x * rotSin, rotCos + pow(axisY.z, 2.0) * nRotCos, 0.0,
        0.0,                                            0.0,                                            0.0,                                  1.0
    );

    world_pos = rotY * world_pos;

    if (USE_WORLD_Y > 0.0)
    {
        float angleA = (-0.5 * PI *
                        sin(2.0 * PI * pitch)) / 2.0;
        rotSin = sin(angleA);
        rotCos = cos(angleA);
        nRotCos = 1.0 - rotCos;
        vec3 axisA = CAMERARIGHT;
        mat4 rotA = mat4( // Just some simple maths
            rotCos + pow(axisA.x, 2.0) * nRotCos, axisA.y * axisA.x * nRotCos + axisA.z * rotSin, axisA.z * axisA.x * nRotCos - axisA.y * rotSin, 0.0,
            axisA.x * axisA.y * nRotCos - axisA.z * rotSin, rotCos + pow(axisA.y, 2.0) * nRotCos, axisA.z * axisA.y * nRotCos + axisA.x * rotSin, 0.0,
            axisA.x * axisA.z * nRotCos + axisA.y * rotSin, axisA.y * axisA.z * nRotCos - axisA.x * rotSin, rotCos + pow(axisA.z, 2.0) * nRotCos, 0.0,
            0.0,                                            0.0,                                            0.0,                                  1.0
        );

        world_pos = rotA * world_pos;
    }
    
    world_pos.xyz += entPos;

    world_pos.y += (sin(0.5 * TIMEPARAMS.x * PI + entPos.x * entPos.z * 0.1)) * 0.15;
    world_pos.y += 0.22;

	gl_Position = MatrixP * MatrixV * world_pos;

	PS_TEXCOORD = TEXCOORD0;
	PS_POS = world_pos.xyz;
}    minecraftify_ent.ps�
  // Fragment shader

#ifdef GL_ES
    precision highp float;
#endif

uniform mat4 MatrixW;

#ifdef TRIPLE_ATLAS
    uniform sampler2D SAMPLER[6];
#else
    uniform sampler2D SAMPLER[5];
#endif

#ifndef LIGHTING_H
    #define LIGHTING_H

    varying vec3 PS_POS;
    // xy = min, zw = max
    uniform vec4 LIGHTMAP_WORLD_EXTENTS;
    #define LIGHTMAP_TEXTURE SAMPLER[3]
    #ifndef LIGHTMAP_TEXTURE
        #error If you use lighting, you must #define the sampler that the lightmap belongs to
    #endif

    vec3 CalculateLightingContribution()
    {
        vec2 uv = (PS_POS.xz - LIGHTMAP_WORLD_EXTENTS.xy) * LIGHTMAP_WORLD_EXTENTS.zw;
        return texture2D(LIGHTMAP_TEXTURE, uv).rgb;
    }
#endif

varying vec3 PS_TEXCOORD;

uniform mat4 COLOUR_XFORM;
uniform vec3 PARAMS;
uniform vec3 FLOAT_PARAMS;
uniform vec4 OCEAN_BLEND_PARAMS;

#define ALPHA_TEST PARAMS.x
#define LIGHT_OVERRIDE PARAMS.y
#define BLOOM_TOGGLE PARAMS.z

uniform vec4 OCEAN_WORLD_EXTENTS;
#define OCEAN_SAMPLER SAMPLER[4]

#define ENT_Z_FLOOR floor(FLOAT_PARAMS.z)

void main()
{
    vec4 textureColor;
    vec2 coord = PS_TEXCOORD.xy;

    #ifdef TRIPLE_ATLAS
        if (PS_TEXCOORD.z < 0.5)
        {
            textureColor = texture2D(SAMPLER[0], coord);
        }
        else if (PS_TEXCOORD.z < 1.5)
        {
            textureColor = texture2D(SAMPLER[1], coord);
        }
        else
        {
            textureColor = texture2D(SAMPLER[5], coord);
        }
    #else
        if (PS_TEXCOORD.z < 0.5)
        {
            textureColor = texture2D(SAMPLER[0], coord);
        }
        else
        {
            textureColor = texture2D(SAMPLER[1], coord);
        }
    #endif

	if (BLOOM_TOGGLE == 1.0)
	{
		gl_FragColor = vec4(0.0, 0.0, 0.0, textureColor.a);
		return;
	}

    if(FLOAT_PARAMS.z - ENT_Z_FLOOR > 0.0)
    {
    	if(PS_POS.y < -0.05)
    	{
    		discard;
    	}
    }

    if(ALPHA_TEST > 0.0)
    {
        if(textureColor.a >= ALPHA_TEST)
        {
            gl_FragColor = textureColor;
        }
        else
        {
            discard;
        }
    }
    else
    {
        gl_FragColor = textureColor * COLOUR_XFORM;
		gl_FragColor.rgb = min(gl_FragColor.rgb, gl_FragColor.a);

		vec2 world_uv = (PS_POS.xz - OCEAN_WORLD_EXTENTS.xy) * OCEAN_WORLD_EXTENTS.zw;
		vec3 world_tint = texture2D(OCEAN_SAMPLER, world_uv).rgb;
		gl_FragColor.rgb = mix(gl_FragColor.rgb, gl_FragColor.rgb * world_tint.rgb, OCEAN_BLEND_PARAMS.x);

        vec3 light = CalculateLightingContribution();
        gl_FragColor.rgb *= max(light.rgb, vec3(LIGHT_OVERRIDE, LIGHT_OVERRIDE, LIGHT_OVERRIDE));
    }
}                                   	      
      