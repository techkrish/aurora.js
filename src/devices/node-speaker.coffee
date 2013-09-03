class NodeSpeakerDevice extends AV.EventEmitter
    AV.AudioDevice.register(NodeSpeakerDevice)
    
    try 
        Speaker = require('speaker')
        Readable = require('stream').Readable
        
    @supported: Speaker?
    
    constructor: (@sampleRate, @channels) ->
        @speaker = new Speaker
            channels: @channels
            sampleRate: @sampleRate
            bitDepth: 32
            float: true
            signed: true
            
        @buffer = null
        @arr = null
        @currentFrame = 0
        @ended = false
            
        # setup a node readable stream and pipe to speaker output
        @input = new Readable
        @input._read = @refill
        @input.pipe @speaker
                
    refill: (n) =>
        {arr,buffer} = this
        
        # reuse the same buffers if possible
        len = n / 4
        if arr?.length isnt len
            @arr = arr = new Float32Array(len)
            
        @emit 'refill', arr
        return if @ended
        
        if buffer?.length isnt n
            @buffer = buffer = new Buffer(n)
            
        # copy the data from the Float32Array into the node buffer
        offset = 0
        for frame in arr
            buffer.writeFloatLE(frame, offset)
            offset += 4
        
        @input.push buffer
        @currentFrame += len / @channels
        
    destroy: ->
        @ended = true
        @input.push null
        
    getDeviceTime: ->
        return @currentFrame # TODO: make this more accurate