module HDF5

using Base: unsafe_convert
using Requires: @require
using Mmap: Mmap
# needed for filter(f, tuple) in julia 1.3
using Compat
using UUIDs: uuid4

### PUBLIC API ###

export @read,
    @write,
    h5open,
    h5read,
    h5write,
    h5rewrite,
    h5writeattr,
    h5readattr,
    create_attribute,
    open_attribute,
    read_attribute,
    write_attribute,
    delete_attribute,
    rename_attribute,
    attributes,
    attrs,
    create_dataset,
    open_dataset,
    read_dataset,
    write_dataset,
    create_group,
    open_group,
    copy_object,
    open_object,
    delete_object,
    move_link,
    create_datatype,
    commit_datatype,
    open_datatype,
    create_property,
    group_info,
    object_info,
    dataspace,
    datatype,
    Filters,
    Drivers

### The following require module scoping ###

# file, filename, name,
# get_chunk, get_datasets,
# get_access_properties, get_create_properties,
# root, readmmap,
# iscontiguous, iscompact, ischunked,
# ishdf5, ismmappable,
# refresh
# start_swmr_write
# create_external, create_external_dataset

### Types
# H5DataStore, Attribute, File, Group, Dataset, Datatype, Opaque,
# Dataspace, Object, Properties, VLen, ChunkStorage, Reference

h5doc(name) = "[`$name`](https://portal.hdfgroup.org/display/HDF5/$(name))"

include("api/api.jl")
include("properties.jl")
include("context.jl")
include("types.jl")
include("file.jl")
include("objects.jl")
include("groups.jl")
include("datatypes.jl")
include("typeconversions.jl")
include("dataspaces.jl")
include("virtual.jl")
include("datasets.jl")
include("attributes.jl")
include("readwrite.jl")
include("references.jl")
include("show.jl")
include("api_midlevel.jl")
include("highlevel.jl")

# Functions that require special handling

const libversion = API.h5_get_libversion()
const HAS_PARALLEL = Ref(false)
const HAS_ROS3 = Ref(false)

"""
    has_parallel()

Returns `true` if the HDF5 libraries were compiled with parallel support,
and if parallel functionality was loaded into HDF5.jl.

For the second condition to be true, MPI.jl must be imported before HDF5.jl.
"""
has_parallel() = HAS_PARALLEL[]

"""
    has_ros3()

Returns `true` if the HDF5 libraries were compiled with ros3 support
"""
has_ros3() = HAS_ROS3[]

function __init__()
    # HDF5.API.__init__() is run first
    #
    # initialize default properties
    ASCII_LINK_PROPERTIES.char_encoding = :ascii
    ASCII_LINK_PROPERTIES.create_intermediate_group = true
    UTF8_LINK_PROPERTIES.char_encoding = :utf8
    UTF8_LINK_PROPERTIES.create_intermediate_group = true
    ASCII_ATTRIBUTE_PROPERTIES.char_encoding = :ascii
    UTF8_ATTRIBUTE_PROPERTIES.char_encoding = :utf8

    @require FileIO = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549" begin
        @require OrderedCollections = "bac558e1-5e72-5ebc-8fee-abe8a469f55d" include(
            "fileio.jl"
        )
    end
    @require H5Zblosc = "c8ec2601-a99c-407f-b158-e79c03c2f5f7" begin
        set_blosc!(p::Properties, val::Bool) =
            val && push!(Filters.FilterPipeline(p), H5Zblosc.BloscFilter())
        set_blosc!(p::Properties, level::Integer) =
            push!(Filters.FilterPipeline(p), H5Zblosc.BloscFilter(; level=level))
    end

    return nothing
end

include("deprecated.jl")

end  # module
