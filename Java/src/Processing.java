import WavFile.WavFile;

import javax.sound.sampled.AudioInputStream;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;

public class Processing {

    private int blocklen = 32;

    private int samplingrate;
    private double T;

    private double[] bandSplit_State_1;
    private double[] bandSplit_State_2;

    private double bandSplit_Frequency = 800.0f;
    private double bandSplit_Q = 1.0f/Math.sqrt(2);

    private double bandSplit_Radians;
    private double bandSplit_wa;
    private double bandSplit_G;
    private double bandSplit_R;
    private double bandSplit_MulState1;
    private double bandSplit_MulIn;

    // [lp, bp, hp][L, R]
    private float[][] energyRatio_Tau_Fast_ms;
    private float[][] energyRatio_Tau_Slow_ms;
    private float[][] energyRatio_State_Fast;
    private float[][] energyRatio_State_Slow;
    private float[][] energyRatio_Alpha_Fast;
    private float[][] energyRatio_Alpha_Slow;
    private float[][] energyRatio_Alpha_Fast_MinusOne;
    private float[][] energyRatio_Alpha_Slow_MinusOne;
    // [LP, BP, HP, WB]
    private float[] detectOnsets_ThreshBase;
    private float[] detectOnsets_ThreshRaise;
    private float[] detectOnsets_Param1;
    private float[] detectOnsets_Decay;

    private float rms_rec;
    private float alpha;

    public Processing() {

        AudioInputStream audioInputStream;
        String filename = "F:/Dropbox/IHAB-RL/[2019] Onset Detection/Java/Recording 112534-110519a.wav";

        String fileName2 = "threshold.txt";
        File file = new File(fileName2);
        file.delete();

        try
        {
            // Open the wav file specified as the first argument
            WavFile wavFile = WavFile.openWavFile(new File(filename));
            // Get the number of audio channels in the wav file
            int numChannels = wavFile.getNumChannels();
            samplingrate = (int) wavFile.getSampleRate();
            double[][] buffer = new double[numChannels][(int) wavFile.getNumFrames()];
            wavFile.readFrames(buffer, 0, (int) wavFile.getNumFrames());
            // Close the wavFile
            wavFile.close();

            T = 1.0f / samplingrate;
            alpha = 0.1f / samplingrate;

            bandSplit_State_1 = new double[2];
            bandSplit_State_2 = new double[2];

            bandSplit_Radians = this.bandSplit_Frequency * 2 * Math.PI;
            bandSplit_wa = (2.0f / T) * Math.tan(bandSplit_Radians * T / 2.0f);
            bandSplit_G = bandSplit_wa * T / 2.0f;
            bandSplit_R = 0.5f / bandSplit_Q;
            bandSplit_MulState1 = 2.0f * bandSplit_R + bandSplit_G;
            bandSplit_MulIn = 1.0f / (1.0f + 2.0f * bandSplit_R * bandSplit_G + bandSplit_G * bandSplit_G);

            // [lp, bp, hp, wb][L, R]
            energyRatio_Tau_Fast_ms = new float[][] {{3.0f, 3.0f}, {2.0f, 2.0f}, {1.0f, 1.0f}, {2.0f, 2.0f}};
            energyRatio_Tau_Slow_ms = new float[][] {{20.0f, 20.0f}, {20.0f, 20.0f}, {20.0f, 20.0f}, {20.0f, 20.0f}};
            energyRatio_State_Fast = new float[4][2];
            energyRatio_State_Slow = new float[4][2];
            energyRatio_Alpha_Fast = new float[][] {
                    {(float) (1.0f - Math.exp(-1.0f / (this.energyRatio_Tau_Fast_ms[0][0] * 0.001 * samplingrate))),
                            (float) (1.0f - Math.exp(-1.0f / (this.energyRatio_Tau_Fast_ms[0][1] * 0.001 * samplingrate)))},
                    {(float) (1.0f - Math.exp(-1.0f / (this.energyRatio_Tau_Fast_ms[1][0] * 0.001 * samplingrate))),
                            (float) (1.0f - Math.exp(-1.0f / (this.energyRatio_Tau_Fast_ms[1][1] * 0.001 * samplingrate)))},
                    {(float) (1.0f - Math.exp(-1.0f / (this.energyRatio_Tau_Fast_ms[2][0] * 0.001 * samplingrate))),
                            (float) (1.0f - Math.exp(-1.0f / (this.energyRatio_Tau_Fast_ms[2][1] * 0.001 * samplingrate)))},
                    {(float) (1.0f - Math.exp(-1.0f / (this.energyRatio_Tau_Fast_ms[3][0] * 0.001 * samplingrate))),
                            (float) (1.0f - Math.exp(-1.0f / (this.energyRatio_Tau_Fast_ms[3][1] * 0.001 * samplingrate)))}
            };
            energyRatio_Alpha_Slow = new float[][] {
                    {(float) (1.0f - Math.exp(-1.0f / (this.energyRatio_Tau_Slow_ms[0][0] * 0.001 * samplingrate))),
                            (float) (1.0f - Math.exp(-1.0f / (this.energyRatio_Tau_Slow_ms[0][1] * 0.001 * samplingrate)))},
                    {(float) (1.0f - Math.exp(-1.0f / (this.energyRatio_Tau_Slow_ms[1][0] * 0.001 * samplingrate))),
                            (float) (1.0f - Math.exp(-1.0f / (this.energyRatio_Tau_Slow_ms[1][1] * 0.001 * samplingrate)))},
                    {(float) (1.0f - Math.exp(-1.0f / (this.energyRatio_Tau_Slow_ms[2][0] * 0.001 * samplingrate))),
                            (float) (1.0f - Math.exp(-1.0f / (this.energyRatio_Tau_Slow_ms[2][1] * 0.001 * samplingrate)))},
                    {(float) (1.0f - Math.exp(-1.0f / (this.energyRatio_Tau_Slow_ms[2][0] * 0.001 * samplingrate))),
                            (float) (1.0f - Math.exp(-1.0f / (this.energyRatio_Tau_Slow_ms[2][1] * 0.001 * samplingrate)))}
            };
            energyRatio_Alpha_Fast_MinusOne = new float[][] {
                    {(float) (- Math.exp(-1.0f / (this.energyRatio_Tau_Fast_ms[0][0] * 0.001 * samplingrate))),
                            (float) (- Math.exp(-1.0f / (this.energyRatio_Tau_Fast_ms[0][1] * 0.001 * samplingrate)))},
                    {(float) (- Math.exp(-1.0f / (this.energyRatio_Tau_Fast_ms[1][0] * 0.001 * samplingrate))),
                            (float) (- Math.exp(-1.0f / (this.energyRatio_Tau_Fast_ms[1][1] * 0.001 * samplingrate)))},
                    {(float) (- Math.exp(-1.0f / (this.energyRatio_Tau_Fast_ms[2][0] * 0.001 * samplingrate))),
                            (float) (- Math.exp(-1.0f / (this.energyRatio_Tau_Fast_ms[2][1] * 0.001 * samplingrate)))},
                    {(float) (- Math.exp(-1.0f / (this.energyRatio_Tau_Fast_ms[3][0] * 0.001 * samplingrate))),
                            (float) (- Math.exp(-1.0f / (this.energyRatio_Tau_Fast_ms[3][1] * 0.001 * samplingrate)))}
            };
            energyRatio_Alpha_Slow_MinusOne = new float[][] {
                    {(float) - Math.exp(-1.0f / (this.energyRatio_Tau_Slow_ms[0][0] * 0.001 * samplingrate)),
                            (float) - Math.exp(-1.0f / (this.energyRatio_Tau_Slow_ms[0][1] * 0.001 * samplingrate))},
                    {(float) - Math.exp(-1.0f / (this.energyRatio_Tau_Slow_ms[1][0] * 0.001 * samplingrate)),
                            (float) - Math.exp(-1.0f / (this.energyRatio_Tau_Slow_ms[1][1] * 0.001 * samplingrate))},
                    {(float) - Math.exp(-1.0f / (this.energyRatio_Tau_Slow_ms[2][0] * 0.001 * samplingrate)),
                            (float) - Math.exp(-1.0f / (this.energyRatio_Tau_Slow_ms[2][1] * 0.001 * samplingrate))},
                    {(float) - Math.exp(-1.0f / (this.energyRatio_Tau_Slow_ms[2][0] * 0.001 * samplingrate)),
                            (float) - Math.exp(-1.0f / (this.energyRatio_Tau_Slow_ms[2][1] * 0.001 * samplingrate))}
            };
            // [LP, BP, HP, WB]
            detectOnsets_ThreshBase = new float[] {8.0f * 16000 / samplingrate, 8.0f * 16000 / samplingrate, 8.0f * 16000 / samplingrate, 8.0f * 16000 / samplingrate};
            detectOnsets_ThreshRaise = new float[] {1.0f * 16000 / samplingrate, 1.0f * 16000 / samplingrate, 1.0f * 16000 / samplingrate, 1.0f * 16000 / samplingrate};
            detectOnsets_Param1 = new float[] {8.0f * 8000 / samplingrate, 8.0f * 8000 / samplingrate, 8.0f * 8000 / samplingrate, 8.0f * 8000 / samplingrate};
            detectOnsets_Decay = new float[] {0.999565488225982f * 14000 / samplingrate, 0.999130541287371f * 14000 / samplingrate,
                    0.998695158311656f * 14000 / samplingrate, 0.999565488225982f * 14000 / samplingrate};

            // "Bring signal up to standard"
            float[][] bufferFloat = new float[buffer[0].length][buffer.length];

            for (int iChannel = 0; iChannel < buffer.length; iChannel++) {
                for (int iSample = 0; iSample < buffer[0].length; iSample++) {
                    bufferFloat[iSample][iChannel] = (float) buffer[iChannel][iSample];
                }
            }
            process(bufferFloat);
        }
        catch(Exception e) {
            System.err.println(e);
        }
    }

    protected void process(float[][] buffer) {

        int onsets = 0;

        int nBlocks = (int) Math.floor((float)buffer.length / blocklen);
        //nBlocks = 1000;

        float[] timescale = new float[nBlocks];

        int iIn = 0;
        float[] block_left = new float[blocklen];
        float[] block_right = new float[blocklen];

        for (int iBlock = 0; iBlock < nBlocks; iBlock++) {

            // Fetch data from buffer to fill block of length blocklen
            for (int iSample = 0; iSample < blocklen; iSample++) {
                block_left[iSample] = buffer[iIn + iSample][0];
                block_right[iSample] = buffer[iIn + iSample][1];
            }
            iIn += blocklen;

            float data = onsetDetection(block_left, block_right);
            if (data == 1.0f) {
                onsets++;
                String fileName2 = "threshold.txt";
                try {
                    BufferedWriter writer = new BufferedWriter(new FileWriter(fileName2, true));


                    writer.append(" " + iBlock + ",");


                    writer.close();
                } catch (Exception e) { }

            }

        }

        System.out.println("Onset Detected: " + onsets);
        //send(dataOut);
    }

    protected float onsetDetection(float[] block_left, float[] block_right) {

        // left
        float[][] bands_left = bandSplit(block_left, 0);
        // right
        float[][] bands_right = bandSplit(block_right, 1);

        float onsets = detectOnsets(bands_left, bands_right, block_left, block_right);
        return onsets;

    }

    protected float detectOnsets(float[][] bands_left, float[][] bands_right, float[] block_left, float[] block_right) {

        float[][] flags = new float[4][2];
        float flag = 0.0f;
        float[] threshold;// = addElementwise(this.detectOnsets_ThreshBase, this.detectOnsets_ThreshRaise);
        float rms = 0.5f * (rms(block_left) + rms(block_right));
        this.rms_rec = this.alpha * rms + (1.0f - this.alpha) * this.rms_rec;

        float[] energy_lp_left = energyRatio(getChannel(bands_left, 0), 0, 0);
        float[] energy_bp_left = energyRatio(getChannel(bands_left, 1), 1, 0);
        float[] energy_hp_left = energyRatio(getChannel(bands_left, 2), 2, 0);
        float[] energy_wb_left = energyRatio(block_left, 3, 0);
        float[] energy_lp_right = energyRatio(getChannel(bands_right, 0), 0, 1);
        float[] energy_bp_right = energyRatio(getChannel(bands_right, 1), 1, 1);
        float[] energy_hp_right = energyRatio(getChannel(bands_right, 2), 2, 1);
        float[] energy_wb_right = energyRatio(block_right, 3, 1);

        for (int iSample = 0; iSample < blocklen; iSample++) {

            threshold = addElementwise(this.detectOnsets_ThreshBase, this.detectOnsets_ThreshRaise);

            float max = 0;


            /**
             *
             *  PROBLEM THRESHOLD GOES TO INFINITY! BLOCKLENGTH SEEMS TO BE SPECIFIC!
             *
             */

            if (rms > rms_rec) {

                if (energy_lp_left[iSample] > threshold[0]) {
                    flags[0][0] = 1.0f;
                    max += (energy_lp_left[iSample] - threshold[0]);
                }
                if (energy_bp_left[iSample] > threshold[1]) {
                    flags[1][0] = 1.0f;
                    max += (energy_bp_left[iSample] - threshold[1]);
                }
                if (energy_hp_left[iSample] > threshold[2]) {
                    flags[2][0] = 1.0f;
                    max += (energy_hp_left[iSample] - threshold[2]);
                }
                if (energy_wb_left[iSample] > threshold[3]) {
                    flags[3][0] = 1.0f;
                    max += (energy_wb_left[iSample] - threshold[3]);
                }
                if (energy_lp_right[iSample] > threshold[0]) {
                    flags[0][1] = 1.0f;
                    max += (energy_lp_left[iSample] - threshold[0]);
                }
                if (energy_bp_right[iSample] > threshold[1]) {
                    flags[1][1] = 1.0f;
                    max += (energy_bp_left[iSample] - threshold[1]);
                }
                if (energy_hp_right[iSample] > threshold[2]) {
                    flags[2][1] = 1.0f;
                    max += (energy_hp_left[iSample] - threshold[2]);
                }
                if (energy_wb_right[iSample] > threshold[3]) {
                    flags[3][1] = 1.0f;
                    max += (energy_wb_left[iSample] - threshold[3]);
                }

            }

            // If more than one band has registered a peak then return 1, else 0
            if ((flags[0][0] + flags[1][0] + flags[2][0] + flags[3][0] +
                    flags[0][1] + flags[1][1] + flags[2][1] + flags[3][1]) > 1.0f) {
                flag = 1.0f;
                this.detectOnsets_ThreshRaise = multiplyElementwise(
                        detectOnsets_Param1, threshold);

                float[] exceed = new float[] {max, max, max, max};

                //this.detectOnsets_ThreshRaise = addElementwise(this.detectOnsets_ThreshRaise, exceed);
                addArray(this.detectOnsets_ThreshRaise, exceed);

                //System.out.println("Exceed: " + max);
            }
            //this.detectOnsets_ThreshRaise = multiplyElementwise(
            //        this.detectOnsets_ThreshRaise, this.detectOnsets_Decay);
            multiplyArray(detectOnsets_ThreshRaise, detectOnsets_Decay);
        }

        return flag;
    }

    protected float rms(float[] signal) {
        float out = 0;
        for (int iSample = 0; iSample < signal.length; iSample++) {
            out += signal[iSample] * signal[iSample];
        }
        out /= signal.length;
        return (float) Math.sqrt(out);
    }

    protected float[] getChannel(float[][] in, int chan) {
        float[] out = new float[in.length];
        for (int iSample = 0; iSample < in.length; iSample++) {
            out[iSample] = in[iSample][chan];
        }
        return out;
    }

    protected void addArray(float[] a, float[] b) {
        for (int iCol = 0; iCol < a.length; iCol++) {
            a[iCol] += b[iCol];
        }
    }

    protected void multiplyArray(float[] a, float[] b) {
        for (int iCol = 0; iCol < a.length; iCol++) {
            a[iCol] *= b[iCol];
        }
    }

    protected float[] multiplyElementwise(float[] a, float[] b) {
        float[] out = new float[a.length];
        for (int iCol = 0; iCol < a.length; iCol++) {
            out[iCol] = a[iCol] * b[iCol];
        }
        return out;
    }

    /*protected float[] addElementwise(float[] a, float[] b) {
        float[] out = new float[a.length];
        for (int iCol = 0; iCol < a.length; iCol++) {
            out[iCol] = a[iCol] + b[iCol];
        }
        return out;
    }*/

    protected float[][] bandSplit(float[] signal, int chan) {

        /**
         *  Perform a bandsplit via state variable filter
         *
         *  input:  float[blocklen] signal
         *          int chan [0, 1] left/right for correct filter states
         *  output: float[blocklen][3] output (blocklen x [lp_L, bp_L, hp_L])
         *
         */

        float ylp, ybp, yhp, tmp_1, tmp_2;

        float[][] output = new float[this.blocklen][3];

        for (int iSample = 0; iSample < this.blocklen; iSample ++) {

            yhp = (float) ((signal[iSample] - bandSplit_MulState1 * bandSplit_State_1[chan] -
                    bandSplit_State_2[chan]) * bandSplit_MulIn);


            tmp_1 = (float) (yhp * bandSplit_G);

            ybp =  (float) (bandSplit_State_1[chan] + tmp_1);

            bandSplit_State_1[chan] = ybp + tmp_1;

            tmp_2 = (float) (ybp * bandSplit_G);

            ylp = (float) (bandSplit_State_2[chan] + tmp_2);

            bandSplit_State_2[chan] = ylp + tmp_2;

            output[iSample][0] = ylp;
            output[iSample][1] = ybp;
            output[iSample][2] = yhp;

        }

        return output;
    }

    protected float[] energyRatio(float[] signal, int band, int chan) {

        /**
         * Energy Ratio of signal
         *
         * Signal input format is float[blocklen] (single channel)
         *
         * Signal output format is float[blocklen] (single channel)
         *
         * band, chan: needed to target specific filter states (lp, bp, hp, wb)
         *
         */

        float[] signal_square = multiplyElementwise(signal, signal);

        float[] signal_filtered_Fast = filter(signal_square, energyRatio_Alpha_Fast, energyRatio_Alpha_Fast_MinusOne, band, chan, 0);
        float[] signal_filtered_Slow = filter(signal_square, energyRatio_Alpha_Slow, energyRatio_Alpha_Slow_MinusOne, band, chan, 1);

        float[] ratio = new float[this.blocklen];

        for (int iSample = 0; iSample < blocklen; iSample++) {
            ratio[iSample] = signal_filtered_Fast[iSample] / signal_filtered_Slow[iSample];
        }

        return ratio;
    }

    protected float[] filter(float[] signal, float[][] coeff_b, float[][] coeff_a, int band, int chan, int fast_slow) {

        /**
         *  single channel IIR filter
         *
         *  Input format of signal is float[blocklen]
         *
         *  coeff_b is b[0]
         *  coeff_a is a[1]; a[0] = 1
         *
         *  band: [lp, bp, hp]
         *  chan: [1, 2] (L, R)
         *  fast_slow = [0, 1] either fast or slow
         *
         *  (layout to account for state memory)
         *
         */

        float[] output = new float[signal.length];
        float tmp;

        if (fast_slow == 0) {
            for (int iSample = 0; iSample < signal.length; iSample++) {
                tmp = coeff_b[band][chan] * signal[iSample] - coeff_a[band][chan] * energyRatio_State_Fast[band][chan];
                output[iSample] = tmp;
                energyRatio_State_Fast[band][chan] = tmp;
            }
        } else{
            for (int iSample = 0; iSample < signal.length; iSample++) {
                tmp = coeff_b[band][chan] * signal[iSample] - coeff_a[band][chan] * energyRatio_State_Slow[band][chan];
                output[iSample] = tmp;
                energyRatio_State_Slow[band][chan] = tmp;
            }
        }

        return output;
    }

}
