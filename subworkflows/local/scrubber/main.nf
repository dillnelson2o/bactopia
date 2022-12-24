//
// scrubber - Scrub human reads from FASTQ files
//
include { initOptions } from '../../../lib/nf/functions'
options = initOptions(params.containsKey("options") ? params.options : [:], 'srahumanscrubber')
options.is_module = params.wf == 'scrubber' ? true : false
options.args = ""
options.ignore = [".db"]
download_database = true
if (params.scrubber_db) {
    if (file(params.scrubber_db).isFile()) {
        download_database = false
    }
}

include { SRAHUMANSCRUBBER_INITDB } from '../../../modules/nf-core/srahumanscrubber/initdb/main' addParams( )
include { SRAHUMANSCRUBBER_SCRUB } from '../../../modules/nf-core/srahumanscrubber/scrub/main' addParams( options: options )

workflow SCRUBBER {
    take:
    reads // channel: [ val(meta), [ reads ] ]

    main:
    ch_versions = Channel.empty()

    if (download_database) {
        SRAHUMANSCRUBBER_INITDB()
        ch_versions = ch_versions.mix(SRAHUMANSCRUBBER_INITDB.out.versions.first())

        SRAHUMANSCRUBBER_SCRUB(reads, SRAHUMANSCRUBBER_INITDB.out.db)
    } else {
        SRAHUMANSCRUBBER_SCRUB(reads, file(params.scrubber_db))
    }

    ch_versions = ch_versions.mix(SRAHUMANSCRUBBER_SCRUB.out.versions.first())

    emit:
    scrubbed = SRAHUMANSCRUBBER_SCRUB.out.scrubbed
    versions = ch_versions // channel: [ versions.yml ]
}
