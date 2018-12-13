/**
 * @file StreamPacketSender.c
 * @author Ambroz Bizjak <ambrop7@gmail.com>
 * 
 * @section LICENSE
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the author nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <misc/debug.h>

#include "StreamPacketSender.h"

static void input_handler_send (StreamPacketSender *o, uint8_t *data, int data_len)
{
    DebugObject_Access(&o->d_obj);
    ASSERT(data_len > 0)
    
    // limit length to MTU and remember
    if (data_len > o->output_mtu) {
        o->sending_len = o->output_mtu;
    } else {
        o->sending_len = data_len;
    }
    
    // send
    PacketPassInterface_Sender_Send(o->output, data, o->sending_len);
}

static void output_handler_done (StreamPacketSender *o)
{
    DebugObject_Access(&o->d_obj);
    
    // done
    StreamPassInterface_Done(&o->input, o->sending_len);
}

void StreamPacketSender_Init (StreamPacketSender *o, PacketPassInterface *output, BPendingGroup *pg)
{
    ASSERT(PacketPassInterface_GetMTU(output) > 0)
    
    // init arguments
    o->output = output;
    
    // remember output MTU
    o->output_mtu = PacketPassInterface_GetMTU(output);
    
    // init input
    StreamPassInterface_Init(&o->input, (StreamPassInterface_handler_send)input_handler_send, o, pg);
    
    // init output
    PacketPassInterface_Sender_Init(o->output, (PacketPassInterface_handler_done)output_handler_done, o);
    
    DebugObject_Init(&o->d_obj);
}

void StreamPacketSender_Free (StreamPacketSender *o)
{
    DebugObject_Free(&o->d_obj);
    
    // free input
    StreamPassInterface_Free(&o->input);
}

StreamPassInterface * StreamPacketSender_GetInput (StreamPacketSender *o)
{
    DebugObject_Access(&o->d_obj);
    
    return &o->input;
}
